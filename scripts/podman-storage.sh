#!/usr/bin/env bash
#
# Configure rootless podman storage for the filesystem it sits on. overlay is
# refused on btrfs, and a leftover store dir for another driver overrides
# storage.conf, so: pick candidates, clear stale stores, verify with podman.
# Idempotent.
#
#   --dry-run    print what would change, touch nothing
#   --quiet      only print on change or error
#   --diagnose   dump the state podman actually sees, change nothing
set -euo pipefail

MARKER='# managed by .mico (scripts/podman-storage.sh) - edits are overwritten'
FUSE_OVERLAYFS=/usr/bin/fuse-overlayfs

dry_run=0
quiet=0
diagnose=0
conf_changed=0
verify_output=""

# $USER is unset under home-manager activation and systemd units.
user_name="${USER:-$(id -un)}"

for arg in "$@"; do
  case "$arg" in
  --dry-run) dry_run=1 ;;
  --quiet) quiet=1 ;;
  --diagnose) diagnose=1 ;;
  *)
    printf 'podman-storage: unknown argument %s\n' "$arg" >&2
    exit 2
    ;;
  esac
done

storage_root="${PODMAN_STORAGE_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/containers/storage}"
storage_conf="${PODMAN_STORAGE_CONF:-${XDG_CONFIG_HOME:-$HOME/.config}/containers/storage.conf}"

say() {
  ((quiet)) || printf 'podman-storage: %s\n' "$1"
}

changed() {
  printf 'podman-storage: %s\n' "$1"
}

warn() {
  printf 'podman-storage: warning: %s\n' "$1" >&2
}

act() {
  if ((dry_run)); then
    printf 'podman-storage: would run: %s\n' "$*"
    return 0
  fi
  "$@"
}

have_systemd() {
  command -v systemctl >/dev/null && [[ -d /run/systemd/system ]]
}

stop_podman_units() {
  have_systemd || return 0
  act systemctl --user stop podman.socket podman.service 2>/dev/null || true
}

start_podman_socket() {
  have_systemd || return 0
  systemctl --user is-enabled podman.socket &>/dev/null || return 0
  act systemctl --user start podman.socket 2>/dev/null || true
}

if ! command -v podman >/dev/null && ((diagnose == 0)); then
  say "podman not installed, nothing to do"
  exit 0
fi

# Filesystem of the deepest existing ancestor; the store may not exist yet.
fs_type() {
  local path="$1"
  while [[ ! -e $path && $path != / ]]; do
    path="$(dirname "$path")"
  done
  if command -v findmnt >/dev/null; then
    findmnt --noheadings --output FSTYPE --target "$path" 2>/dev/null && return 0
  fi
  stat -f -c %T "$path" 2>/dev/null || true
}

if ((diagnose)); then
  dump_file() {
    local path="$1"
    printf '\n--- %s\n' "$path"
    if [[ -L $path ]]; then
      printf 'symlink -> %s\n' "$(readlink "$path")"
      [[ -e $path ]] || printf 'TARGET IS MISSING (dangling)\n'
    fi
    if [[ -e $path ]]; then
      sed 's/^/    /' "$path" 2>/dev/null || printf 'unreadable\n'
    elif [[ ! -L $path ]]; then
      printf 'absent\n'
    fi
  }

  printf '=== podman ===\n'
  printf 'binary: %s\n' "$(command -v podman || echo 'NOT INSTALLED')"
  podman --version 2>/dev/null || true
  printf 'fuse-overlayfs: %s\n' "$(command -v fuse-overlayfs || echo 'NOT INSTALLED')"
  printf 'btrfs (progs): %s\n' "$(command -v btrfs || echo 'NOT INSTALLED')"

  printf '\n=== env ===\n'
  for var in CONTAINERS_STORAGE_CONF CONTAINERS_CONF XDG_CONFIG_HOME XDG_DATA_HOME DOCKER_HOST; do
    printf '%s=%s\n' "$var" "${!var-<unset>}"
  done

  printf '\n=== subuid/subgid (needed to own layer files) ===\n'
  for f in /etc/subuid /etc/subgid; do
    printf '%-12s %s\n' "$f" "$(grep "^${user_name}:" "$f" 2>/dev/null || echo "no entry for $user_name")"
  done
  printf 'newuidmap: %s\n' "$(command -v newuidmap || echo 'NOT INSTALLED')"

  printf '\n=== filesystems ===\n'
  printf 'HOME          %s -> %s\n' "$HOME" "$(fs_type "$HOME")"
  printf 'storage root  %s -> %s\n' "$storage_root" "$(fs_type "$storage_root")"

  printf '\n=== storage.conf candidates ===\n'
  [[ -n ${CONTAINERS_STORAGE_CONF-} ]] && dump_file "$CONTAINERS_STORAGE_CONF"
  dump_file "$storage_conf"
  dump_file /etc/containers/storage.conf

  printf '\n=== store contents ===\n'
  if [[ -d $storage_root ]]; then
    ls -la "$storage_root" 2>/dev/null || true
  else
    printf '%s does not exist\n' "$storage_root"
  fi

  printf '\n=== systemd --user ===\n'
  if have_systemd; then
    for unit in podman.socket podman.service; do
      printf '%-16s enabled=%s active=%s\n' "$unit" \
        "$(systemctl --user is-enabled "$unit" 2>&1 || true)" \
        "$(systemctl --user is-active "$unit" 2>&1 || true)"
    done
  else
    printf 'no systemd\n'
  fi

  printf '\n=== podman info (full error if any) ===\n'
  podman info --format \
    'driver={{.Store.GraphDriverName}} root={{.Store.GraphRoot}} conf={{.Store.ConfigFile}}' \
    2>&1 || true
  printf '\n'
  exit 0
fi

fs="$(fs_type "$storage_root")"
if [[ -z $fs ]]; then
  warn "could not determine filesystem for $storage_root, leaving storage alone"
  exit 0
fi

# Candidate strategies, best first. Only btrfs needs a config at all.
strategies=()
case "$fs" in
btrfs)
  strategies+=(btrfs)
  [[ -x $FUSE_OVERLAYFS ]] && strategies+=(fuse-overlayfs)
  ;;
*)
  strategies+=(default)
  ;;
esac

say "$storage_root is on $fs, trying: ${strategies[*]}"

strategy_driver() {
  case "$1" in
  btrfs) printf 'btrfs\n' ;;
  fuse-overlayfs | default) printf 'overlay\n' ;;
  esac
}

conf_is_ours() {
  [[ -f $storage_conf ]] && grep -qF "$MARKER" "$storage_conf"
}

# A symlink here is a stale home-manager link into the read-only nix store.
if [[ -L $storage_conf ]]; then
  link_target="$(readlink "$storage_conf" 2>/dev/null || true)"
  if [[ -e $storage_conf ]]; then
    changed "replacing home-manager symlink $storage_conf -> $link_target"
  else
    changed "removing dangling symlink $storage_conf -> ${link_target:-?}"
  fi
  act rm -f "$storage_conf"
  conf_changed=1
fi

if [[ -e $storage_conf ]] && ! conf_is_ours; then
  warn "$storage_conf exists and is not managed here, not touching it"
  warn "it must select a driver that works on $fs, or podman will fail"
  exit 0
fi

write_conf() {
  local strategy="$1" body
  case "$strategy" in
  btrfs)
    body='# Home is on btrfs; the default overlay driver cannot back onto it.
[storage]
driver = "btrfs"'
    ;;
  fuse-overlayfs)
    body='# Home is on btrfs, where the kernel overlay driver is refused. Rootless
# overlay through fuse-overlayfs works on any filesystem.
[storage]
driver = "overlay"

[storage.options.overlay]
mount_program = "'"$FUSE_OVERLAYFS"'"'
    ;;
  default)
    if conf_is_ours; then
      changed "removing $storage_conf, $fs needs no driver override"
      act rm -f "$storage_conf"
      conf_changed=1
    fi
    return 0
    ;;
  esac

  if conf_is_ours && [[ "$(cat "$storage_conf")" == "$MARKER"$'\n'"$body" ]]; then
    say "storage.conf already configured for $strategy"
    return 0
  fi

  changed "writing $storage_conf for $strategy"
  act mkdir -p "$(dirname "$storage_conf")"
  if ((dry_run)); then
    printf 'podman-storage: would write %s config\n' "$strategy"
  else
    printf '%s\n%s\n' "$MARKER" "$body" >"$storage_conf"
  fi
  conf_changed=1
}

# podman <= 5 also creates <driver>-layers and <driver>-images dirs.
KNOWN_DRIVERS=(overlay overlay2 btrfs vfs zfs aufs devicemapper)

existing_drivers() {
  local d
  for d in "${KNOWN_DRIVERS[@]}"; do
    if [[ -d $storage_root/$d || -d $storage_root/$d-layers || -d $storage_root/$d-images ]]; then
      printf '%s\n' "$d"
    fi
  done
}

# Layer files are owned by subuids, so plain rm fails; use podman's namespace.
remove_store() {
  if ((dry_run)); then
    printf 'podman-storage: would run: podman unshare rm -rf %s\n' "$storage_root"
    return 0
  fi

  if podman unshare rm -rf "$storage_root" 2>/dev/null && [[ ! -e $storage_root ]]; then
    return 0
  fi

  # No usable user namespace; the store may still be plain user-owned.
  rm -rf "$storage_root" 2>/dev/null || true
  [[ ! -e $storage_root ]]
}

clear_stale_store() {
  local expected="$1" found stale=()

  while IFS= read -r found; do
    [[ -n $found ]] || continue
    [[ $found == "$expected" ]] || stale+=("$found")
  done < <(existing_drivers)

  ((${#stale[@]})) || return 0

  case "$storage_root" in
  */containers/storage) ;;
  *)
    warn "refusing to remove unexpected storage path $storage_root"
    exit 1
    ;;
  esac

  changed "found ${stale[*]} state in the store, but $expected is required"
  changed "removing the store - podman would keep using ${stale[0]} otherwise"
  changed "local images and containers are dropped, they are rebuildable"

  stop_podman_units

  if remove_store; then
    conf_changed=1
    return 0
  fi

  warn "could not fully remove $storage_root"
  warn "rootless layers are owned by subuids, so this needs podman's user namespace:"
  warn "    podman unshare rm -rf $storage_root"
  if ! grep -q "^${user_name}:" /etc/subuid 2>/dev/null; then
    warn "/etc/subuid has no range for $user_name, which is why the namespace is unavailable"
    warn "fix with: sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $user_name"
  fi
  exit 1
}

verify() {
  verify_output="$(podman info --format '{{.Store.GraphDriverName}}' 2>&1)" && return 0
  return 1
}

settled=""
last_error=""

for strategy in "${strategies[@]}"; do
  driver="$(strategy_driver "$strategy")"

  write_conf "$strategy"
  clear_stale_store "$driver"

  if ((dry_run)); then
    say "would verify $strategy with podman info"
    settled="$strategy"
    break
  fi

  if verify && [[ $verify_output == "$driver" ]]; then
    settled="$strategy"
    break
  fi

  last_error="$verify_output"
  if ((${#strategies[@]} > 1)); then
    warn "$strategy did not work, falling back"
    warn "podman said: ${last_error%%$'\n'*}"
  fi
done

if ((conf_changed)); then
  stop_podman_units
  start_podman_socket
fi

if [[ -n $settled ]]; then
  say "storage is configured for $settled"
  exit 0
fi

warn "no working storage driver found for $fs"
warn "podman reported:"
printf '%s\n' "$last_error" | sed 's/^/    /' >&2
if [[ $fs == "btrfs" && ! -x $FUSE_OVERLAYFS ]]; then
  warn "installing fuse-overlayfs would add a fallback: sudo pacman -S fuse-overlayfs"
fi
exit 1
