#!/usr/bin/env bash
#
# Bootstrap this machine from nothing to a fully configured environment.
#
# Idempotent: every phase detects whether it has already been done, so re-running
# is safe and is in fact the intended way to apply changes to the system half of
# the setup (the pacman lists).
#
# Usage:
#   ./bootstrap.sh                 detect host, do everything, prompt before
#                                  anything destructive
#   ./bootstrap.sh --host wsl      force a host instead of auto-detecting
#   ./bootstrap.sh --yes           assume yes, no prompts (for unattended runs)
#   ./bootstrap.sh --no-pacman     skip all pacman work
#   ./bootstrap.sh --no-remove     install pacman packages but never remove any
#   ./bootstrap.sh --dry-run       print what would happen, change nothing
#   ./bootstrap.sh --check         report pacman drift and exit; read-only, no sudo
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HOST=""
ASSUME_YES=0
DO_PACMAN=1
DO_REMOVE=1
DRY=0
CHECK_ONLY=0

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'
else
  C_RESET=""
  C_BOLD=""
  C_RED=""
  C_GREEN=""
  C_YELLOW=""
  C_BLUE=""
fi

step() { printf '\n%s==>%s %s%s%s\n' "$C_BLUE" "$C_RESET" "$C_BOLD" "$*" "$C_RESET"; }
ok() { printf '  %s+%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
skip() { printf '  %s-%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
warn() { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die() {
  printf '\n%serror:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2
  exit 1
}

run() {
  if ((DRY)); then
    printf '  %s?%s would run: %s\n' "$C_YELLOW" "$C_RESET" "$*"
  else
    "$@"
  fi
}

confirm() {
  ((ASSUME_YES)) && return 0
  ((DRY)) && return 1
  local reply
  read -r -p "  ? $1 [y/N] " reply
  [[ $reply == [yY]* ]]
}

read_list() {
  [[ -f $1 ]] || return 0
  sed -e 's/#.*$//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' "$1"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --host)
    HOST="${2:-}"
    shift 2
    ;;
  --host=*)
    HOST="${1#*=}"
    shift
    ;;
  --yes | -y)
    ASSUME_YES=1
    shift
    ;;
  --no-pacman)
    DO_PACMAN=0
    shift
    ;;
  --no-remove)
    DO_REMOVE=0
    shift
    ;;
  --dry-run | -n)
    DRY=1
    shift
    ;;
  --check)
    CHECK_ONLY=1
    shift
    ;;
  -h | --help)
    sed -n '3,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
    exit 0
    ;;
  *) die "unknown argument: $1" ;;
  esac
done

detect_host() {
  if [[ -n ${WSL_DISTRO_NAME:-} ]] \
    || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    echo wsl
  else
    echo arch
  fi
}

[[ -n $HOST ]] || HOST="$(detect_host)"
[[ $HOST == "arch" || $HOST == "wsl" ]] \
  || die "host must be 'arch' or 'wsl', got '$HOST'"

# --check: report pacman drift. Read-only, no sudo.
if ((CHECK_ONLY)); then
  step "Pacman drift for host '$HOST'"

  command -v pacman >/dev/null || die "pacman not found, nothing to check"

  mapfile -t declared < <(
    {
      read_list "$REPO/packages/common.txt"
      read_list "$REPO/packages/$HOST.txt"
      read_list "$REPO/packages/aur-common.txt"
      read_list "$REPO/packages/aur-$HOST.txt"
      # paru is bootstrapped, not declared.
      command -v paru >/dev/null && pacman -Qq paru 2>/dev/null || true
      command -v paru >/dev/null && pacman -Qq paru-bin 2>/dev/null || true
    } | sort -u
  )
  mapfile -t migrated < <(read_list "$REPO/packages/migrated.txt" | sort -u)
  mapfile -t installed < <(pacman -Qq | sort -u)
  mapfile -t explicit < <(pacman -Qqe | sort -u)

  in_list() {
    local needle="$1"
    shift
    local x
    for x in "$@"; do [[ $x == "$needle" ]] && return 0; done
    return 1
  }

  drift=0

  # A dependency-only package can vanish with its parent, so it counts as drift.
  missing=()
  dep_only=()
  for p in "${declared[@]}"; do
    if ! in_list "$p" "${installed[@]}"; then
      missing+=("$p")
    elif ! in_list "$p" "${explicit[@]}"; then
      dep_only+=("$p")
    fi
  done

  if ((${#missing[@]})); then
    drift=1
    warn "declared but NOT installed (${#missing[@]}):"
    printf '      %s\n' "${missing[@]}"
    printf '      fix: ./bootstrap.sh\n'
  else
    ok "all ${#declared[@]} declared packages are installed"
  fi

  if ((${#dep_only[@]})); then
    drift=1
    warn "declared but installed only as a dependency (${#dep_only[@]}):"
    printf '      %s\n' "${dep_only[@]}"
    printf '      fix: sudo pacman -D --asexplicit %s\n' "${dep_only[*]}"
  fi

  undeclared=()
  for p in "${explicit[@]}"; do
    in_list "$p" "${declared[@]}" && continue
    in_list "$p" "${migrated[@]}" && continue
    undeclared+=("$p")
  done
  if ((${#undeclared[@]})); then
    drift=1
    warn "installed explicitly but NOT declared (${#undeclared[@]}):"
    printf '      %s\n' "${undeclared[@]}"
    printf '      fix: add to packages/%s.txt, or pacman -Rns / -D --asdeps\n' "$HOST"
    if printf '%s\n' "${undeclared[@]}" | grep -q -- '-debug$'; then
      printf '      note: *-debug entries are makepkg artifacts; remove them\n'
    fi
  else
    ok "no undeclared explicit packages"
  fi

  stale=()
  for p in "${migrated[@]}"; do
    in_list "$p" "${explicit[@]}" && stale+=("$p")
  done
  if ((${#stale[@]})); then
    drift=1
    warn "moved to nix but still installed via pacman (${#stale[@]}):"
    printf '      %s\n' "${stale[@]}"
    printf '      fix: ./bootstrap.sh   (it offers to remove them)\n'
  else
    ok "no migrated packages left on pacman"
  fi

  if ((drift)); then
    printf '\n%sdrift detected%s\n' "$C_YELLOW" "$C_RESET"
    exit 1
  fi
  printf '\n%sin sync%s\n' "$C_GREEN" "$C_RESET"
  exit 0
fi

step "Bootstrapping host '$HOST' from $REPO"
((DRY)) && warn "dry run - nothing will be changed"

step "Preflight"

[[ -f "$REPO/flake.nix" ]] || die "no flake.nix in $REPO - is this the right directory?"

if [[ $REPO != "$HOME/.mico" ]]; then
  warn "repo is at $REPO but the flake expects ~/.mico"
  warn "the nvim symlink and the mico wrapper hardcode ~/.mico, so move it or"
  warn "update home/common.nix and hosts/*.nix"
fi

if [[ $EUID -eq 0 ]]; then
  die "do not run this as root - it needs your user's home directory. It will
       call sudo where required."
fi

if ! command -v sudo >/dev/null; then
  die "sudo is required"
fi

((DRY)) || sudo -v

ok "running as $(whoami), home $HOME"

# nixpkgs' non-interactive bash has no `compgen`, which makepkg/paru need.
bash_path="$(command -v bash || true)"
bash_real=""
[[ -n $bash_path ]] && bash_real="$(readlink -f "$bash_path" 2>/dev/null || echo "$bash_path")"
# Resolved, because .envrc's shadow bash and /bin are symlinks to /usr/bin/bash.
if [[ -n $bash_real && $bash_real != /usr/bin/bash ]]; then
  warn "bash on PATH resolves to $bash_real, not /usr/bin/bash"
  if [[ -n ${IN_NIX_SHELL:-} ]]; then
    warn "cause: you are inside a nix shell (IN_NIX_SHELL=${IN_NIX_SHELL})"
  fi
  warn "that bash has no compgen, so manual makepkg/paru runs will fail"
fi

step "Store location"

if [[ -e /nix ]]; then
  skip "/nix already exists"
elif ! command -v findmnt >/dev/null; then
  skip "findmnt unavailable, cannot detect filesystem"
elif [[ "$(findmnt -no FSTYPE / 2>/dev/null)" == "btrfs" ]]; then
  # Snapshots are not recursive, so this keeps the store out of root snapshots.
  ok "root is btrfs - creating a dedicated subvolume for /nix"
  run sudo btrfs subvolume create /nix
else
  skip "root is not btrfs, the installer will create a plain /nix"
fi

step "Nix"

nix_env() {
  local profile=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  # Explicit return 0: a trailing `[[ ]] && .` would trip set -e.
  if [[ -e $profile ]]; then
    # shellcheck source=/dev/null
    . "$profile"
  fi
  return 0
}

if command -v nix >/dev/null || [[ -e /nix/var/nix/profiles/default/bin/nix ]]; then
  nix_env
  skip "nix already installed ($(nix --version 2>/dev/null || echo 'version unknown'))"
else
  if [[ $HOST == "wsl" ]] && ! [[ -d /run/systemd/system ]]; then
    die "systemd is not running. WSL needs the following in /etc/wsl.conf:

           [boot]
           systemd=true

         then 'wsl --shutdown' from Windows, and re-run this script."
  fi

  # This endpoint installs Determinate Nix, not upstream Nix.
  ok "installing nix, multi-user (Determinate Nix distribution)"
  if ((DRY)); then
    warn "would run the Determinate nix-installer"
  else
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
      | sh -s -- install linux --no-confirm
  fi
  nix_env
fi

if ! ((DRY)) && ! command -v nix >/dev/null; then
  die "nix is installed but not on PATH. Open a new shell and re-run this script."
fi

step "Nix daemon settings"

if [[ -f /etc/nix/nix.conf ]] && grep -q '^auto-optimise-store' /etc/nix/nix.conf; then
  skip "auto-optimise-store already configured"
else
  # A root daemon setting, so home-manager cannot express it.
  ok "enabling auto-optimise-store"
  if ((DRY)); then
    warn "would append auto-optimise-store to /etc/nix/nix.conf"
  else
    echo 'auto-optimise-store = true' | sudo tee -a /etc/nix/nix.conf >/dev/null
    sudo systemctl restart nix-daemon || warn "could not restart nix-daemon"
  fi
fi

step "System packages (pacman)"

pacman_ready=0
if ((! DO_PACMAN)); then
  skip "--no-pacman given"
elif ! command -v pacman >/dev/null; then
  skip "pacman not found, not an Arch-based system"
else
  # Arch does not support partial upgrades, so upgrade before installing.
  ok "refreshing package databases and upgrading the system"
  pacman_ready=1
  if ! run sudo pacman -Syu --noconfirm; then
    warn "pacman -Syu failed; skipping package and AUR changes"
    pacman_ready=0
  fi

  mapfile -t wanted < <(
    {
      read_list "$REPO/packages/common.txt"
      read_list "$REPO/packages/$HOST.txt"
    } | sort -u
  )

  missing=()
  dep_only=()
  for p in "${wanted[@]}"; do
    if ! pacman -Qq -- "$p" &>/dev/null; then
      missing+=("$p")
    elif ! pacman -Qqe -- "$p" &>/dev/null; then
      dep_only+=("$p")
    fi
  done

  if ((pacman_ready == 0)); then
    skip "system package changes skipped after failed pacman -Syu"
  elif ((${#missing[@]} == 0)); then
    ok "all ${#wanted[@]} declared system packages already installed"
  else
    ok "installing ${#missing[@]} missing: ${missing[*]}"
    run sudo pacman -S --needed --noconfirm -- "${missing[@]}" \
      || warn "some packages failed - check the names are in the official repos"
  fi

  # `pacman -S --needed` does not change the install reason, so set it here.
  if ((pacman_ready)) && ((${#dep_only[@]})); then
    ok "marking ${#dep_only[@]} dependency-only as explicit: ${dep_only[*]}"
    run sudo pacman -D --asexplicit -- "${dep_only[@]}" \
      || warn "could not update install reasons"
  fi
fi

step "pacman.conf"

if ((! DO_PACMAN)); then
  skip "--no-pacman given"
elif [[ ! -f /etc/pacman.conf ]]; then
  skip "no /etc/pacman.conf"
else
  if grep -qE '^Color' /etc/pacman.conf; then
    skip "Color already enabled"
  elif ((DRY)); then
    warn "would uncomment Color in /etc/pacman.conf"
  else
    ok "enabling Color"
    sudo sed -i 's/^#Color$/Color/' /etc/pacman.conf
  fi

  if grep -qE '^ParallelDownloads' /etc/pacman.conf; then
    skip "ParallelDownloads already set"
  elif ((DRY)); then
    warn "would set ParallelDownloads = 5 in /etc/pacman.conf"
  else
    ok "enabling ParallelDownloads = 5"
    sudo sed -i 's/^#ParallelDownloads.*$/ParallelDownloads = 5/' /etc/pacman.conf
  fi
fi

# Bootstrap paru-bin (prebuilt, avoids a Rust toolchain) with plain makepkg.
step "AUR helper"

AUR_HELPER_PKG=paru-bin

if ((! DO_PACMAN)); then
  skip "--no-pacman given"
elif ! command -v pacman >/dev/null; then
  skip "pacman not found"
elif ((pacman_ready == 0)); then
  skip "pacman upgrade did not complete"
elif command -v paru >/dev/null; then
  skip "paru already installed ($(paru --version 2>/dev/null | head -1))"
elif ((DRY)); then
  warn "would build and install $AUR_HELPER_PKG from the AUR with makepkg"
else
  if ! command -v makepkg >/dev/null; then
    warn "makepkg missing - install base-devel first, then re-run"
  else
    ok "building $AUR_HELPER_PKG from the AUR"
    aur_tmp="$(mktemp -d)"

    # System bash first (compgen) and no mise Go env. Build and install separately
    # so the -debug package that makepkg also emits is not installed.
    if git clone --depth 1 "https://aur.archlinux.org/${AUR_HELPER_PKG}.git" "$aur_tmp/$AUR_HELPER_PKG" \
      && (
        cd "$aur_tmp/$AUR_HELPER_PKG" || exit 1
        env -u GOROOT -u GOPATH -u GOENV \
          PATH="/usr/bin:/usr/local/bin:$PATH" \
          makepkg -s --noconfirm || exit 1
        mapfile -t built < <(
          find . -maxdepth 1 -name '*.pkg.tar.*' ! -name '*-debug-*' ! -name '*.sig' -print
        )
        ((${#built[@]} > 0)) || {
          echo "makepkg produced no installable package" >&2
          exit 1
        }
        sudo pacman -U --noconfirm -- "${built[@]}"
      ); then
      ok "paru installed"
    else
      warn "could not build $AUR_HELPER_PKG - AUR packages will be skipped"
    fi
    rm -rf "$aur_tmp"
  fi
fi

step "AUR packages"

if ((! DO_PACMAN)); then
  skip "--no-pacman given"
elif ! command -v pacman >/dev/null; then
  skip "pacman not found"
elif ((pacman_ready == 0)); then
  skip "pacman upgrade did not complete"
else
  mapfile -t aur_wanted < <(
    {
      read_list "$REPO/packages/aur-common.txt"
      read_list "$REPO/packages/aur-$HOST.txt"
    } | sort -u
  )

  aur_missing=()
  for p in "${aur_wanted[@]}"; do
    if ! pacman -Qq -- "$p" &>/dev/null; then
      aur_missing+=("$p")
    fi
  done

  if ((${#aur_wanted[@]} == 0)); then
    skip "no AUR packages declared"
  elif ((${#aur_missing[@]} == 0)); then
    ok "all ${#aur_wanted[@]} declared AUR packages already installed"
  elif ! command -v paru >/dev/null; then
    warn "paru unavailable, skipping: ${aur_missing[*]}"
  else
    ok "installing ${#aur_missing[@]} from the AUR: ${aur_missing[*]}"
    # Same as above: system bash for makepkg, no mise Go env.
    run env -u GOROOT -u GOPATH -u GOENV \
      PATH="/usr/bin:/usr/local/bin:$PATH" \
      paru -S --needed --noconfirm -- "${aur_missing[@]}" \
      || warn "some AUR packages failed"
  fi
fi

step "Git identity"

if [[ -f "$HOME/.gitconfig.local" ]] \
  && git config --file "$HOME/.gitconfig.local" --get user.email >/dev/null 2>&1; then
  skip "$HOME/.gitconfig.local already has an identity"
elif ((DRY)); then
  warn "would prompt for git user.name and user.email"
elif ((ASSUME_YES)); then
  warn "no ~/.gitconfig.local and --yes given; set it later or commits will fail:"
  warn "  git config --file ~/.gitconfig.local user.name  '...'"
  warn "  git config --file ~/.gitconfig.local user.email '...'"
else
  read -r -p "  ? git user.name: " git_name
  read -r -p "  ? git user.email: " git_email
  if [[ -n $git_name && -n $git_email ]]; then
    git config --file "$HOME/.gitconfig.local" user.name "$git_name"
    git config --file "$HOME/.gitconfig.local" user.email "$git_email"
    ok "wrote ~/.gitconfig.local (never committed - this repo is public)"
  else
    warn "skipped, commits will fail until you set this"
  fi
fi

step "home-manager"

if command -v home-manager >/dev/null; then
  ok "switching with the installed home-manager"
  run home-manager switch --flake "$REPO#$HOST" -b backup
else
  ok "first activation, running home-manager from the flake"
  run nix run github:nix-community/home-manager -- \
    switch --flake "$REPO#$HOST" -b backup
fi

# After activation, so the nix replacements already exist.
step "Reconciling pacman against nix"

if ((! DO_REMOVE)); then
  skip "--no-remove given"
elif ! command -v pacman >/dev/null; then
  skip "pacman not found"
else
  mapfile -t candidates < <(read_list "$REPO/packages/migrated.txt" | sort -u)

  present=()
  for p in "${candidates[@]}"; do
    if pacman -Qqe -- "$p" &>/dev/null; then
      present+=("$p")
    fi
  done

  if ((${#present[@]} == 0)); then
    ok "no migrated packages left on pacman"
  else
    warn "these are installed via pacman but now come from nix:"
    printf '      %s\n' "${present[*]}"
    if confirm "remove them?"; then
      removed=()
      blocked=()
      for p in "${present[@]}"; do
        if run sudo pacman -Rns --noconfirm -- "$p"; then
          removed+=("$p")
        else
          blocked+=("$p")
        fi
      done
      ((${#removed[@]})) && ok "removed: ${removed[*]}"
      if ((${#blocked[@]})); then
        warn "kept because another pacman package depends on them: ${blocked[*]}"
        warn "they remain explicit so pacman will not orphan/remove required dependencies"
      fi
    else
      skip "left in place; nix wins by PATH order anyway"
    fi
  fi
fi

# Outside the systemd gate: `podman compose` needs these even without the socket.
step "Podman"

# Rootless networking needs tun. The node can exist without a driver behind it,
# so actually open it.
kernel_release="$(uname -r)"

tun_usable() {
  [[ -c /dev/net/tun ]] || return 1
  (exec 3<>/dev/net/tun) 2>/dev/null
}

if tun_usable; then
  skip "/dev/net/tun opens (tun driver present)"
elif [[ $HOST == wsl ]]; then
  warn "/dev/net/tun does not open; enable WSL's tun support on the Windows side"
elif [[ ! -d /lib/modules/$kernel_release ]]; then
  warn "no module tree at /lib/modules/$kernel_release"
  warn "the running kernel was replaced by an upgrade - REBOOT, then rerun this"
  warn "until then no kernel module can load, so rootless podman has no network"
elif ! command -v modprobe >/dev/null; then
  warn "no modprobe - cannot load the tun module for rootless networking"
else
  if [[ -c /dev/net/tun ]]; then
    ok "/dev/net/tun exists but does not open - loading the tun driver"
  else
    ok "loading the tun module (rootless container networking needs it)"
  fi

  if run sudo modprobe tun && { ((DRY)) || tun_usable; }; then
    ((DRY)) || ok "/dev/net/tun opens now"
  else
    warn "tun still unusable - rootless container networking will not work"
    warn "  uname -r:            $kernel_release"
    warn "  module tree:         $(ls -d "/lib/modules/$kernel_release" 2>/dev/null || echo missing)"
    warn "  tun.ko:              $(find "/lib/modules/$kernel_release" -name 'tun.ko*' -print -quit 2>/dev/null || echo 'not found')"
    warn "  builtin:             $(grep -c '/tun\.ko' "/lib/modules/$kernel_release/modules.builtin" 2>/dev/null || echo 0)"
    warn "if uname -r differs from the installed kernel, reboot to fix this"
  fi
fi

# modprobe above does not survive a reboot.
tun_modconf=/etc/modules-load.d/tun.conf
if [[ $HOST == wsl ]]; then
  skip "WSL kernel modules are managed by Windows; not writing $tun_modconf"
elif [[ -f $tun_modconf ]] && grep -qx 'tun' "$tun_modconf"; then
  skip "tun already declared in $tun_modconf"
elif [[ ! -d /etc/modules-load.d ]]; then
  skip "no /etc/modules-load.d - not a systemd system"
else
  ok "declaring tun in $tun_modconf so it loads at boot"
  tun_tmp="$(mktemp)"
  printf 'tun\n' >"$tun_tmp"
  run sudo install -Dm644 "$tun_tmp" "$tun_modconf"
  rm -f "$tun_tmp"
fi

# netavark's nftables backend fails on WSL2 and minimal kernels.
containers_conf_src="$REPO/config/containers/containers.conf"
containers_conf_dst=/etc/containers/containers.conf.d/01-firewall.conf
if ! command -v podman >/dev/null; then
  skip "podman not installed"
elif [[ ! -f $containers_conf_src ]]; then
  warn "missing $containers_conf_src"
elif [[ -f $containers_conf_dst ]] && cmp -s "$containers_conf_src" "$containers_conf_dst"; then
  skip "$containers_conf_dst already up to date"
else
  ok "configuring system-wide podman network firewall driver ($containers_conf_dst)"
  run sudo install -Dm644 "$containers_conf_src" "$containers_conf_dst"
fi

podman_storage_script="$REPO/scripts/podman-storage.sh"
if ! command -v podman >/dev/null; then
  skip "podman not installed"
elif [[ ! -x $podman_storage_script ]]; then
  warn "missing $podman_storage_script - skipping storage setup"
else
  run "$podman_storage_script"
fi

step "Login manager"

sddm_conf_src="$REPO/config/sddm/10-hide-system-users.conf"
sddm_conf_dst=/etc/sddm.conf.d/10-hide-system-users.conf
if ! command -v sddm >/dev/null && [[ ! -d /usr/lib/sddm ]]; then
  skip "sddm not installed"
elif [[ ! -f $sddm_conf_src ]]; then
  warn "missing $sddm_conf_src"
elif [[ -f $sddm_conf_dst ]] && cmp -s "$sddm_conf_src" "$sddm_conf_dst"; then
  skip "sddm already hides nologin accounts"
else
  ok "hiding nologin accounts (nix build users) from the sddm greeter"
  run sudo install -Dm644 "$sddm_conf_src" "$sddm_conf_dst"
fi

step "User services"

if ! command -v systemctl >/dev/null || ! [[ -d /run/systemd/system ]]; then
  skip "systemd not running"
else
  if systemctl --user is-enabled podman.socket &>/dev/null; then
    skip "podman.socket already enabled"
  elif command -v podman >/dev/null; then
    ok "enabling podman.socket (DOCKER_HOST points at it)"
    run systemctl --user enable --now podman.socket || warn "could not enable podman.socket"
  else
    skip "podman not installed"
  fi

  if systemctl --user is-enabled nix-gc.timer &>/dev/null; then
    ok "nix-gc.timer active (weekly garbage collection)"
  else
    warn "nix-gc.timer not active - it is created by home-manager, so"
    warn "run 'systemctl --user daemon-reload' and re-check"
  fi

  # home-manager owns the syncthing unit, so never `systemctl enable` it here.
  if [[ $HOST == "wsl" ]]; then
    skip "syncthing is not configured on WSL by design"
  elif ! systemctl --user list-unit-files syncthing.service &>/dev/null \
    || [[ -z "$(systemctl --user list-unit-files --no-legend syncthing.service 2>/dev/null)" ]]; then
    warn "syncthing.service missing - run 'mico switch' first, home-manager creates it"
  elif systemctl --user is-active syncthing.service &>/dev/null; then
    ok "syncthing.service running (GUI at http://127.0.0.1:8384)"
  else
    ok "starting syncthing.service"
    run systemctl --user start syncthing.service || warn "could not start syncthing"
  fi
fi

step "System maintenance timers"

enable_system_unit() {
  local unit="$1" why="$2"

  if ! systemctl list-unit-files "$unit" &>/dev/null \
    || [[ -z "$(systemctl list-unit-files --no-legend "$unit" 2>/dev/null)" ]]; then
    skip "$unit not available (package missing?)"
    return 0
  fi

  if systemctl is-enabled "$unit" &>/dev/null; then
    skip "$unit already enabled"
    return 0
  fi

  if ((DRY)); then
    warn "would enable $unit ($why)"
    return 0
  fi

  ok "enabling $unit ($why)"
  sudo systemctl enable --now "$unit" || warn "could not enable $unit"
  return 0
}

if ! command -v systemctl >/dev/null || ! [[ -d /run/systemd/system ]]; then
  skip "systemd not running"
elif [[ $HOST == "wsl" ]]; then
  skip "disk maintenance timers not applicable inside WSL"

  enable_system_unit ollama.service "local LLM server on 127.0.0.1:11434"
else
  enable_system_unit fstrim.timer "weekly SSD TRIM"

  # "-" is the escaped mountpoint "/".
  enable_system_unit "btrfs-scrub@-.timer" "monthly btrfs scrub of /"

  enable_system_unit smartd.service "SMART disk health monitoring"

  enable_system_unit paccache.timer "weekly pacman cache pruning"

  enable_system_unit reflector.timer "mirror ranking"
fi

# nix.gc only collects the user profile; root profile generations need this.
step "System profile GC"

GC_UNIT=/etc/systemd/system/nix-gc-system.service
GC_TIMER=/etc/systemd/system/nix-gc-system.timer

if ! command -v systemctl >/dev/null || ! [[ -d /run/systemd/system ]]; then
  skip "systemd not running"
elif [[ -f $GC_TIMER ]] && systemctl is-enabled nix-gc-system.timer &>/dev/null; then
  skip "nix-gc-system.timer already installed and enabled"
elif ((DRY)); then
  warn "would install and enable $GC_TIMER"
else
  ok "installing weekly system-profile GC timer"

  sudo tee "$GC_UNIT" >/dev/null <<'UNIT'
[Unit]
Description=Collect old root/system nix profile generations
Documentation=https://github.com/Miconen/.mico

[Service]
Type=oneshot
ExecStart=/nix/var/nix/profiles/default/bin/nix-collect-garbage --delete-older-than 30d
UNIT

  sudo tee "$GC_TIMER" >/dev/null <<'UNIT'
[Unit]
Description=Weekly root/system nix garbage collection

[Timer]
OnCalendar=weekly
Persistent=true
RandomizedDelaySec=1h

[Install]
WantedBy=timers.target
UNIT

  sudo systemctl daemon-reload
  sudo systemctl enable --now nix-gc-system.timer \
    || warn "could not enable nix-gc-system.timer"
fi

step "Done"

cat <<EOF

  Host:      $HOST
  Flake:     $REPO#$HOST
  Switch:    mico switch

  Verify with:

    exec zsh
    mise ls
    which -a git eza zoxide
    readlink -f ~/.config/nvim

EOF

if [[ $HOST == "arch" ]]; then
  cat <<'EOF'
  kitty's font and theme are managed by this repo, so no manual font step is
  needed. If glyphs still look wrong, restart kitty so fontconfig is re-read.

EOF
fi
