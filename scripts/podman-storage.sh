#!/usr/bin/env bash
#
# Configure rootless podman storage for the filesystem it actually sits on.
#
# Why this is a script and not a static config file: the correct graph driver
# depends on the filesystem backing ~/.local/share/containers, which nix cannot
# know at build time. The Arch laptop is btrfs, where the default overlay driver
# refuses to work:
#
#   'overlay' is not supported over btrfs ... backing file system is unsupported
#
# WSL is usually ext4, where overlay is correct and forcing btrfs would break it
# the same way. So detect, then write only what is needed.
#
# Also handles the part a config file cannot: a store already initialized with
# the wrong driver keeps being used (and keeps failing) until it is removed.
#
# Idempotent. Safe to run from bootstrap.sh and from home-manager activation.
#
#   --dry-run    print what would change, touch nothing
#   --quiet      only print on change or error
#   --diagnose   dump the state podman actually sees, change nothing
set -euo pipefail

MARKER='# managed by .mico (scripts/podman-storage.sh) - edits are overwritten'

dry_run=0
quiet=0
diagnose=0
conf_changed=0

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
#
# The failure mode this exists for: a storage.conf that is present but not the
# one podman reads (wrong path, dangling symlink, overridden by an env var), or
# a stale podman.service still holding the previous config.
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

  printf '\n=== env ===\n'
  for var in CONTAINERS_STORAGE_CONF CONTAINERS_CONF XDG_CONFIG_HOME XDG_DATA_HOME DOCKER_HOST; do
    printf '%s=%s\n' "$var" "${!var-<unset>}"
  done

  printf '\n=== filesystems ===\n'
  printf 'HOME          %s -> %s\n' "$HOME" "$(fs_type "$HOME")"
  printf 'storage root  %s -> %s\n' "$storage_root" "$(fs_type "$storage_root")"

  printf '\n=== storage.conf candidates (first readable wins) ===\n'
  [[ -n ${CONTAINERS_STORAGE_CONF-} ]] && dump_file "$CONTAINERS_STORAGE_CONF"
  dump_file "$storage_conf"
  dump_file /etc/containers/storage.conf
  dump_file /usr/share/containers/storage.conf

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

  printf '\n=== podman info ===\n'
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

# Only btrfs needs an override. Everywhere else podman's default (overlay) is
# right, so we deliberately write no config at all.
case "$fs" in
btrfs) want="btrfs" ;;
*) want="overlay" ;;
esac

say "$storage_root is on $fs, driver should be $want"

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
  warn "it must set driver = \"$want\" for this filesystem, or podman will fail"
elif [[ $want == "btrfs" ]]; then
  if conf_is_ours && grep -q 'driver = "btrfs"' "$storage_conf"; then
    say "storage.conf already selects the btrfs driver"
  else
    changed "writing $storage_conf (driver = btrfs)"
    act mkdir -p "$(dirname "$storage_conf")"
    if ((dry_run)); then
      printf 'podman-storage: would write driver = "btrfs"\n'
    else
      cat >"$storage_conf" <<EOF
$MARKER
#
# Home is on btrfs; the default overlay driver cannot back onto it.
# Regenerated by scripts/podman-storage.sh (bootstrap.sh / home-manager).
[storage]
driver = "btrfs"
EOF
    fi
    conf_changed=1
  fi
elif conf_is_ours; then
  # Filesystem changed under us (restore onto ext4, new machine, ...).
  changed "removing $storage_conf, $fs does not need a driver override"
  act rm -f "$storage_conf"
  conf_changed=1
fi

# ---------------------------------------------------------------------------
# Existing store
#
# containers/storage picks the driver whose directory already exists in the
# graphroot, in preference to the one in storage.conf - it will not orphan an
# existing store. So a leftover overlay/ dir silently defeats driver = "btrfs".
#
# The layout is version dependent: podman <= 5 created <driver>-layers and
# <driver>-images alongside <driver>/, podman 6 keeps one db.sql plus <driver>/.
# Matching only on *-layers therefore misses modern stores completely.
# ---------------------------------------------------------------------------
KNOWN_DRIVERS=(overlay overlay2 btrfs vfs zfs aufs devicemapper)

# Every driver with state in the graphroot, one per line.
existing_drivers() {
  local d
  for d in "${KNOWN_DRIVERS[@]}"; do
    if [[ -d $storage_root/$d || -d $storage_root/$d-layers || -d $storage_root/$d-images ]]; then
      printf '%s\n' "$d"
    fi
  done
}

stale_drivers=()
while IFS= read -r found; do
  [[ -n $found ]] || continue
  if [[ $found == "$want" ]]; then
    say "existing store already has a $found dir"
  else
    stale_drivers+=("$found")
  fi
done < <(existing_drivers)

if ((${#stale_drivers[@]})); then
  # Guard the rm: only ever inside the containers storage dir.
  case "$storage_root" in
  */containers/storage) ;;
  *)
    warn "refusing to remove unexpected storage path $storage_root"
    exit 1
    ;;
  esac

  changed "found ${stale_drivers[*]} state in $storage_root, but $want is required"
  changed "removing the store - podman would keep using ${stale_drivers[0]} otherwise"
  changed "local images and containers are dropped, they are rebuildable"

  stop_podman_units
  act rm -rf "$storage_root"
  conf_changed=1
elif ((${#stale_drivers[@]} == 0)) && [[ -z $(existing_drivers) ]]; then
  say "no store initialized yet, podman will create a $want one"
fi

# A running podman.service loaded the old storage config at start and keeps
# using it, so anything talking to DOCKER_HOST keeps seeing the old error even
# after the config is fixed. Bounce it whenever we changed something.
if ((conf_changed)); then
  stop_podman_units
  start_podman_socket
fi

# ---------------------------------------------------------------------------
# Verify, so a silent misconfiguration cannot survive a bootstrap run.
# ---------------------------------------------------------------------------
if ((dry_run)); then
  exit 0
fi

got="$(podman info --format '{{.Store.GraphDriverName}}' 2>/dev/null || true)"
if [[ -z $got ]]; then
  warn "podman info failed - run '$0 --diagnose' to dump the relevant state"
  exit 0
fi

if [[ $got == "$want" ]]; then
  say "podman reports the $got driver"
else
  warn "podman reports '$got' but '$want' was expected"
  warn "run '$0 --diagnose' to see which config podman is actually reading"
fi
