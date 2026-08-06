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

# ---------------------------------------------------------------------------
# output helpers
# ---------------------------------------------------------------------------
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
  # strips comments and blank lines
  [[ -f $1 ]] || return 0
  sed -e 's/#.*$//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' "$1"
}

# ---------------------------------------------------------------------------
# argument parsing
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# host detection
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# --check: report drift between packages/*.txt and what pacman actually has.
# Read-only, needs no sudo, exits 1 if anything is out of sync. This is the
# useful half of the old backup-package-list timer, without the dump.
# ---------------------------------------------------------------------------
if ((CHECK_ONLY)); then
  step "Pacman drift for host '$HOST'"

  command -v pacman >/dev/null || die "pacman not found, nothing to check"

  mapfile -t declared < <(
    {
      read_list "$REPO/packages/common.txt"
      read_list "$REPO/packages/$HOST.txt"
      # AUR packages show up in `pacman -Qqe` like anything else, so they have to
      # count as declared or they would be reported as drift forever.
      read_list "$REPO/packages/aur-common.txt"
      read_list "$REPO/packages/aur-$HOST.txt"
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

  # Declared packages split three ways: absent, present only as somebody else's
  # dependency, or properly explicit. The middle case matters - a dependency-only
  # package can be removed out from under you when its parent goes, so a
  # declaration is not actually satisfied until the install reason is explicit.
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

  # explicitly installed but undeclared
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
    # -debug packages are makepkg by-products, never something you want declared.
    if printf '%s\n' "${undeclared[@]}" | grep -q -- '-debug$'; then
      printf '      note: *-debug entries are makepkg artifacts; remove them\n'
    fi
  else
    ok "no undeclared explicit packages"
  fi

  # moved to nix but pacman still has it. Explicit only: a migrated package that
  # is merely somebody's dependency is not something you chose, and pacman would
  # refuse to remove it anyway.
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

# ---------------------------------------------------------------------------
# 0. preflight
# ---------------------------------------------------------------------------
step "Preflight"

[[ -f "$REPO/flake.nix" ]] || die "no flake.nix in $REPO - is this the right directory?"

if [[ $REPO != "$HOME/.mico" ]]; then
  warn "repo is at $REPO but the flake expects ~/.mico"
  warn "the nvim symlink and the hms alias hardcode ~/.mico, so move it or"
  warn "update home/common.nix and hosts/*.nix"
fi

if [[ $EUID -eq 0 ]]; then
  die "do not run this as root - it needs your user's home directory. It will
       call sudo where required."
fi

if ! command -v sudo >/dev/null; then
  die "sudo is required"
fi

# Warm the sudo timestamp once, so later phases do not each stop for a password.
((DRY)) || sudo -v

ok "running as $(whoami), home $HOME"

# makepkg (and therefore paru) needs bash's `compgen`, which nixpkgs'
# non-interactive bash does not have: it is built with --disable-readline, and
# bash disables programmable completion along with readline. If such a bash wins
# on PATH, AUR builds fail with "compgen: command not found" inside fakeroot.
#
# The AUR phases below prepend /usr/bin to work around it, but warn here too,
# because the same trap catches any manual makepkg or paru run. .envrc shadows
# bash for this repo, so this should normally stay quiet.
bash_path="$(command -v bash || true)"
bash_real=""
[[ -n $bash_path ]] && bash_real="$(readlink -f "$bash_path" 2>/dev/null || echo "$bash_path")"
# Resolve symlinks: .envrc deliberately shadows bash with .direnv/bin/bash, which
# points AT /usr/bin/bash, and /bin is a symlink to /usr/bin on Arch. Comparing
# the unresolved path would warn about the very fix that is working.
if [[ -n $bash_real && $bash_real != /usr/bin/bash ]]; then
  warn "bash on PATH resolves to $bash_real, not /usr/bin/bash"
  if [[ -n ${IN_NIX_SHELL:-} ]]; then
    warn "cause: you are inside a nix shell (IN_NIX_SHELL=${IN_NIX_SHELL})"
  fi
  warn "that bash has no compgen, so manual makepkg/paru runs will fail"
fi

# ---------------------------------------------------------------------------
# 1. btrfs subvolume for /nix (Arch laptop, before nix exists)
# ---------------------------------------------------------------------------
step "Store location"

if [[ -e /nix ]]; then
  skip "/nix already exists"
elif ! command -v findmnt >/dev/null; then
  skip "findmnt unavailable, cannot detect filesystem"
elif [[ "$(findmnt -no FSTYPE / 2>/dev/null)" == "btrfs" ]]; then
  # btrfs snapshots are not recursive, so a nested subvolume keeps the store
  # (many GB on unstable) out of any root snapshot.
  ok "root is btrfs - creating a dedicated subvolume for /nix"
  run sudo btrfs subvolume create /nix
else
  skip "root is not btrfs, the installer will create a plain /nix"
fi

# ---------------------------------------------------------------------------
# 2. install nix
# ---------------------------------------------------------------------------
step "Nix"

nix_env() {
  local profile=/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  # Must not be a trailing `[[ ... ]] && .` - that returns 1 when the profile is
  # absent, and under `set -e` a bare call to this function would kill the
  # script. Explicit `return 0`.
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

  # NOTE: this endpoint installs *Determinate Nix* (their distribution, with
  # determinate-nixd), not upstream Nix - verified by installing it and getting
  # "nix (Determinate Nix 3.21.9) 2.34.8". The --determinate flag toggles their
  # enterprise features, it is NOT what selects the distribution. For strictly
  # upstream Nix, use the official installer from nixos.org instead.
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

# ---------------------------------------------------------------------------
# 3. daemon-level nix settings that a flake cannot set
# ---------------------------------------------------------------------------
step "Nix daemon settings"

if [[ -f /etc/nix/nix.conf ]] && grep -q '^auto-optimise-store' /etc/nix/nix.conf; then
  skip "auto-optimise-store already configured"
else
  # Store deduplication is a daemon setting requiring root, so home-manager
  # cannot express it. Garbage collection itself is a user timer (home/nix-gc.nix).
  ok "enabling auto-optimise-store"
  if ((DRY)); then
    warn "would append auto-optimise-store to /etc/nix/nix.conf"
  else
    echo 'auto-optimise-store = true' | sudo tee -a /etc/nix/nix.conf >/dev/null
    sudo systemctl restart nix-daemon || warn "could not restart nix-daemon"
  fi
fi

# ---------------------------------------------------------------------------
# 4. pacman: the system half of the split
# ---------------------------------------------------------------------------
step "System packages (pacman)"

if ((!DO_PACMAN)); then
  skip "--no-pacman given"
elif ! command -v pacman >/dev/null; then
  skip "pacman not found, not an Arch-based system"
else
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

  if ((${#missing[@]} == 0)); then
    ok "all ${#wanted[@]} declared system packages already installed"
  else
    ok "installing ${#missing[@]} missing: ${missing[*]}"
    # --needed makes this safe to repeat. AUR packages are NOT handled here; they
    # live in packages/aur-*.txt and are installed by paru in a later phase.
    run sudo pacman -S --needed --noconfirm -- "${missing[@]}" \
      || warn "some packages failed - check the names are in the official repos"
  fi

  # A declared package that is only present as somebody else's dependency can be
  # removed when that parent goes. `pacman -S --needed` will NOT fix this: it
  # skips already-installed packages without touching the install reason, so the
  # reason has to be set separately.
  if ((${#dep_only[@]})); then
    ok "marking ${#dep_only[@]} dependency-only as explicit: ${dep_only[*]}"
    run sudo pacman -D --asexplicit -- "${dep_only[@]}" \
      || warn "could not update install reasons"
  fi
fi

# ---------------------------------------------------------------------------
# 4d. pacman.conf niceties
#     Two lines only, both idempotent. Already set on the current laptop, so this
#     is really for a fresh machine.
# ---------------------------------------------------------------------------
step "pacman.conf"

if ((!DO_PACMAN)); then
  skip "--no-pacman given"
elif [[ ! -f /etc/pacman.conf ]]; then
  skip "no /etc/pacman.conf"
else
  # `^Color` and `^ParallelDownloads` - the shipped file has both commented out.
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

# ---------------------------------------------------------------------------
# 4b. AUR helper
#     paru is an AUR package, so no AUR helper can install it - `pacman -S paru`
#     does not work either, it is not in the official repos. It has to be built
#     directly with makepkg once, after which it manages everything else.
#
#     paru-bin, not paru: paru-bin ships a prebuilt binary, whereas paru builds
#     from source and would pull a full Rust toolchain onto every new machine.
# ---------------------------------------------------------------------------
step "AUR helper"

AUR_HELPER_PKG=paru-bin

if ((!DO_PACMAN)); then
  skip "--no-pacman given"
elif ! command -v pacman >/dev/null; then
  skip "pacman not found"
elif command -v paru >/dev/null; then
  skip "paru already installed ($(paru --version 2>/dev/null | head -1))"
elif ((DRY)); then
  warn "would build and install $AUR_HELPER_PKG from the AUR with makepkg"
else
  # makepkg refuses to run as root, which is one reason this script does too.
  # base-devel and git come from packages/common.txt, installed above.
  if ! command -v makepkg >/dev/null; then
    warn "makepkg missing - install base-devel first, then re-run"
  else
    ok "building $AUR_HELPER_PKG from the AUR"
    aur_tmp="$(mktemp -d)"

    # makepkg must run with the system bash first on PATH.
    #
    # nixpkgs' non-interactive bash is built with --disable-readline, which also
    # disables bash's programmable completion, so it has no `compgen`. makepkg's
    # /usr/share/makepkg/util/config.sh calls compgen and dies with
    # "compgen: command not found" inside the fakeroot environment if a nix bash
    # shadows /usr/bin/bash.
    #
    # Prepending rather than replacing, so anything else makepkg needs is still
    # reachable further down PATH.
    #
    # Build and install are separate steps on purpose. `makepkg -si` installs
    # every artifact it produced, and Arch's default OPTIONS=(debug) also emits a
    # <pkg>-debug package - which then shows up as undeclared drift forever.
    # Installing only the non-debug artifacts avoids that without having to
    # rewrite makepkg.conf.
    if git clone --depth 1 "https://aur.archlinux.org/${AUR_HELPER_PKG}.git" "$aur_tmp/$AUR_HELPER_PKG" \
      && (
        cd "$aur_tmp/$AUR_HELPER_PKG" || exit 1
        PATH="/usr/bin:/usr/local/bin:$PATH" makepkg -s --noconfirm || exit 1
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

# ---------------------------------------------------------------------------
# 4c. AUR packages
# ---------------------------------------------------------------------------
step "AUR packages"

if ((!DO_PACMAN)); then
  skip "--no-pacman given"
elif ! command -v pacman >/dev/null; then
  skip "pacman not found"
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
    # paru shells out to makepkg, so it needs the same system-bash-first PATH.
    run env PATH="/usr/bin:/usr/local/bin:$PATH" \
      paru -S --needed --noconfirm -- "${aur_missing[@]}" \
      || warn "some AUR packages failed"
  fi
fi

# ---------------------------------------------------------------------------
# 6. git identity (untracked, because this repo is public)
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# 7. activate home-manager
#    This also installs the language toolchains, because home/mise.nix runs
#    `mise install` as an activation hook.
# ---------------------------------------------------------------------------
step "home-manager"

if command -v home-manager >/dev/null; then
  ok "switching with the installed home-manager"
  run home-manager switch --flake "$REPO#$HOST" -b backup
else
  ok "first activation, running home-manager from the flake"
  run nix run github:nix-community/home-manager -- \
    switch --flake "$REPO#$HOST" -b backup
fi

# ---------------------------------------------------------------------------
# 8. remove pacman packages that nix now provides
#    Deliberately AFTER activation, so the nix replacements already exist.
# ---------------------------------------------------------------------------
step "Reconciling pacman against nix"

if ((!DO_REMOVE)); then
  skip "--no-remove given"
elif ! command -v pacman >/dev/null; then
  skip "pacman not found"
else
  mapfile -t candidates < <(read_list "$REPO/packages/migrated.txt" | sort -u)

  present=()
  for p in "${candidates[@]}"; do
    # -Qqe not -Qq: only offer to remove packages that were explicitly wanted.
    # A migrated package present as somebody else's dependency is not something
    # you chose, and pacman would refuse to remove it anyway.
    #
    # Note `cmd && arr+=(x)` as a bare statement returns 1 when cmd fails, which
    # `set -e` treats as fatal, hence if/then.
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
      if ! run sudo pacman -Rns --noconfirm -- "${present[@]}"; then
        warn "removal blocked by dependencies - demoting to dependency-only instead"
        run sudo pacman -D --asdeps -- "${present[@]}" || true
      fi
    else
      skip "left in place; nix wins by PATH order anyway"
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 9. podman
#
# Deliberately outside the systemd gate below: both of these matter even where
# the rootless socket cannot run, and `podman compose` fails without them.
# home-manager re-runs the storage script on every activation.
# ---------------------------------------------------------------------------
step "Podman"

# Rootless networking (pasta, and slirp4netns) needs a tap device. Without the
# tun module every container build dies at:
#   pasta failed ... Failed to open() /dev/net/tun: No such device
if [[ -e /dev/net/tun ]]; then
  skip "/dev/net/tun present"
elif ! command -v modprobe >/dev/null; then
  warn "no modprobe - cannot load the tun module for rootless networking"
else
  ok "loading the tun module (rootless container networking needs it)"
  run sudo modprobe tun || warn "modprobe tun failed - rootless networking will not work"
fi

# modprobe above does not survive a reboot.
tun_modconf=/etc/modules-load.d/tun.conf
if [[ -f $tun_modconf ]] && grep -qx 'tun' "$tun_modconf"; then
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

podman_storage_script="$REPO/scripts/podman-storage.sh"
if ! command -v podman >/dev/null; then
  skip "podman not installed"
elif [[ ! -x $podman_storage_script ]]; then
  warn "missing $podman_storage_script - skipping storage setup"
else
  # The script is idempotent and prints only when it changes something.
  run "$podman_storage_script"
fi

# ---------------------------------------------------------------------------
# 10. user services
# ---------------------------------------------------------------------------
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

  # Syncthing is declared in hosts/arch.nix, so home-manager creates AND starts
  # the unit during activation - this deliberately does not `systemctl enable` it,
  # which would fight home-manager for ownership. It only reports, and only on
  # hosts where the unit is supposed to exist.
  if [[ $HOST == "wsl" ]]; then
    skip "syncthing is not configured on WSL by design"
  elif ! systemctl --user list-unit-files syncthing.service &>/dev/null \
    || [[ -z "$(systemctl --user list-unit-files --no-legend syncthing.service 2>/dev/null)" ]]; then
    warn "syncthing.service missing - run 'hms' first, home-manager creates it"
  elif systemctl --user is-active syncthing.service &>/dev/null; then
    ok "syncthing.service running (GUI at http://127.0.0.1:8384)"
  else
    ok "starting syncthing.service"
    run systemctl --user start syncthing.service || warn "could not start syncthing"
  fi
fi

# ---------------------------------------------------------------------------
# 9b. system maintenance timers
#     All root-level, all shipped by packages we already declare, all off by
#     default on Arch. Each was verified disabled on the laptop.
# ---------------------------------------------------------------------------
step "System maintenance timers"

# unit -> what it does, and why it is not optional
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
  # No physical disk to trim or scrub, and WSL manages its own storage.
  skip "not applicable inside WSL"
else
  # Discard unused SSD blocks. Without this, sustained write performance on NVMe
  # degrades over time.
  enable_system_unit fstrim.timer "weekly SSD TRIM"

  # Monthly checksum verification of /. btrfs stores checksums but never checks
  # them unless scrubbed, so silent corruption otherwise goes unnoticed until a
  # read fails. The unit name escapes the mountpoint: "-" means "/".
  enable_system_unit "btrfs-scrub@-.timer" "monthly btrfs scrub of /"

  # SMART monitoring. smartmontools was installed but the daemon was off, so it
  # was collecting nothing.
  enable_system_unit smartd.service "SMART disk health monitoring"

  # Prune /var/cache/pacman, which otherwise grows without limit. Complements the
  # nix GC timers rather than duplicating them - different store entirely.
  enable_system_unit paccache.timer "weekly pacman cache pruning"

  # Rank mirrors by speed. Optional in the sense that a slow mirror only costs
  # time, but it costs it on every single install.
  enable_system_unit reflector.timer "mirror ranking"
fi

# ---------------------------------------------------------------------------
# 11. root/system profile garbage collection
#     home/nix-gc.nix only collects THIS user's profile. Root-owned system
#     profile generations - created by nix upgrades and any root-level installs
#     - accumulate unbounded and no user-level flake can reach them.
#
#     This unit lives in /etc/systemd/system, so unlike everything else here it
#     does NOT roll back with a home-manager generation. Unavoidable for
#     root-owned state.
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# done
# ---------------------------------------------------------------------------
step "Done"

cat <<EOF

  Host:      $HOST
  Flake:     $REPO#$HOST
  Switch:    hms

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
