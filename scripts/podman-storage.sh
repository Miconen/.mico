#!/usr/bin/env bash
#
# Configure rootless podman storage for the filesystem it actually sits on.
#
# Why this is a script and not a static config file: the correct graph driver
# depends on the filesystem backing the containers dir, which nix cannot know at
# build time. The laptop is btrfs, where podman's default overlay driver refuses
# to run:
#
#   'overlay' is not supported over btrfs ... backing file system is unsupported
#
# WSL is usually ext4, where overlay is correct and forcing btrfs would break it
# the same way. So detect, then write only what is needed.
#
# Two further things a config file cannot do, both of which caused real failures
# here:
#
#   * containers/storage prefers whichever driver already has a directory in the
#     graphroot over the one in storage.conf - it will not orphan a store. A
#     leftover overlay/ dir therefore silently defeats driver = "btrfs".
#   * whether a driver actually works is only knowable by running podman. On
#     btrfs there are two viable options (the native btrfs driver, or overlay
#     via fuse-overlayfs) and which one is available depends on how podman was
#     built and what is installed.
#
# So: pick candidates from the filesystem, try them in order, verify each with
# podman itself, and keep the first that works.
#
# Idempotent. Safe to run from bootstrap.sh and from home-manager activation.
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

# Overridable for testing. Podman resolves these through XDG, so honour it here
# too - hardcoding ~/.config would write a file podman never reads.
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

# Filesystem of the deepest existing ancestor - the storage dir itself may not
# exist yet on a fresh machine.
fs_type() {
  local path="$1"
  while [[ ! -e $path && $path != / ]]; do
    path="$(dirname "$path")"
  done
  if command -v findmnt >/dev/null; then
    findmnt --noheadings --output FSTYPE --target "$path" 2>/dev/null && return 0
  fi
  # Busybox-free fallback; prints e.g. "btrfs" or "ext2/ext3".
  stat -f -c %T "$path" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# --diagnose: print what podman actually sees and stop.
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# Candidate strategies, best first.
#
# Only btrfs needs anything special. Everywhere else podman's own default is
# right, so we deliberately write no config at all.
# ---------------------------------------------------------------------------
strategies=()
case "$fs" in
btrfs)
  strategies+=(btrfs)
  # Rootless overlay works on any filesystem through fuse-overlayfs, so it is a
  # sound fallback when the native btrfs driver is unavailable.
  [[ -x $FUSE_OVERLAYFS ]] && strategies+=(fuse-overlayfs)
  ;;
*)
  strategies+=(default)
  ;;
esac

say "$storage_root is on $fs, trying: ${strategies[*]}"

# Driver each strategy makes podman report, and therefore the graph dir it uses.
strategy_driver() {
  case "$1" in
  btrfs) printf 'btrfs\n' ;;
  fuse-overlayfs | default) printf 'overlay\n' ;;
  esac
}

# ---------------------------------------------------------------------------
# storage.conf
# ---------------------------------------------------------------------------
conf_is_ours() {
  [[ -f $storage_conf ]] && grep -qF "$MARKER" "$storage_conf"
}

# A symlink at this path is never hand-written - home-manager put it there.
# Earlier versions of this repo managed storage.conf as an xdg.configFile, which
# points into /nix/store; once that generation is garbage collected the link
# dangles, podman silently falls back to /etc (overlay), and writing through the
# link would try to create a file inside the read-only store. Clear it first.
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
  # A hand-written or distro-provided config outranks us.
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

# ---------------------------------------------------------------------------
# Existing store
#
# The layout is version dependent: podman <= 5 created <driver>-layers and
# <driver>-images alongside <driver>/, podman 6 keeps one db.sql plus <driver>/.
# ---------------------------------------------------------------------------
KNOWN_DRIVERS=(overlay overlay2 btrfs vfs zfs aufs devicemapper)

existing_drivers() {
  local d
  for d in "${KNOWN_DRIVERS[@]}"; do
    if [[ -d $storage_root/$d || -d $storage_root/$d-layers || -d $storage_root/$d-images ]]; then
      printf '%s\n' "$d"
    fi
  done
}

# Remove the store when it holds state for a driver we are not about to use.
clear_stale_store() {
  local expected="$1" found stale=()

  while IFS= read -r found; do
    [[ -n $found ]] || continue
    [[ $found == "$expected" ]] || stale+=("$found")
  done < <(existing_drivers)

  ((${#stale[@]})) || return 0

  # Guard the rm: only ever inside the containers storage dir.
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
  act rm -rf "$storage_root"
  conf_changed=1
}

# ---------------------------------------------------------------------------
# Try each strategy, and let podman itself say whether it worked.
# ---------------------------------------------------------------------------
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
