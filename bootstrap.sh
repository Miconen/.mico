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
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

HOST=""
ASSUME_YES=0
DO_PACMAN=1
DO_REMOVE=1
DRY=0

# ---------------------------------------------------------------------------
# output helpers
# ---------------------------------------------------------------------------
if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
  C_RESET=""; C_BOLD=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""
fi

step()  { printf '\n%s==>%s %s%s%s\n' "$C_BLUE" "$C_RESET" "$C_BOLD" "$*" "$C_RESET"; }
ok()    { printf '  %s+%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
skip()  { printf '  %s-%s %s\n' "$C_YELLOW" "$C_RESET" "$*"; }
warn()  { printf '  %s!%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()   { printf '\n%serror:%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

run() {
  if (( DRY )); then
    printf '  %s?%s would run: %s\n' "$C_YELLOW" "$C_RESET" "$*"
  else
    "$@"
  fi
}

confirm() {
  (( ASSUME_YES )) && return 0
  (( DRY )) && return 1
  local reply
  read -r -p "  ? $1 [y/N] " reply
  [[ "$reply" == [yY]* ]]
}

# ---------------------------------------------------------------------------
# argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)      HOST="${2:-}"; shift 2 ;;
    --host=*)    HOST="${1#*=}"; shift ;;
    --yes|-y)    ASSUME_YES=1; shift ;;
    --no-pacman) DO_PACMAN=0; shift ;;
    --no-remove) DO_REMOVE=0; shift ;;
    --dry-run|-n) DRY=1; shift ;;
    -h|--help)   sed -n '3,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)           die "unknown argument: $1" ;;
  esac
done

# ---------------------------------------------------------------------------
# host detection
# ---------------------------------------------------------------------------
detect_host() {
  if [[ -n "${WSL_DISTRO_NAME:-}" ]] \
    || grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
    echo wsl
  else
    echo arch
  fi
}

[[ -n "$HOST" ]] || HOST="$(detect_host)"
[[ "$HOST" == "arch" || "$HOST" == "wsl" ]] \
  || die "host must be 'arch' or 'wsl', got '$HOST'"

step "Bootstrapping host '$HOST' from $REPO"
(( DRY )) && warn "dry run - nothing will be changed"

# ---------------------------------------------------------------------------
# 0. preflight
# ---------------------------------------------------------------------------
step "Preflight"

[[ -f "$REPO/flake.nix" ]] || die "no flake.nix in $REPO - is this the right directory?"

if [[ "$REPO" != "$HOME/.mico" ]]; then
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
(( DRY )) || sudo -v

ok "running as $(whoami), home $HOME"

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
  if [[ -e "$profile" ]]; then
    # shellcheck source=/dev/null
    . "$profile"
  fi
  return 0
}

if command -v nix >/dev/null || [[ -e /nix/var/nix/profiles/default/bin/nix ]]; then
  nix_env
  skip "nix already installed ($(nix --version 2>/dev/null || echo 'version unknown'))"
else
  if [[ "$HOST" == "wsl" ]] && ! [[ -d /run/systemd/system ]]; then
    die "systemd is not running. WSL needs the following in /etc/wsl.conf:

           [boot]
           systemd=true

         then 'wsl --shutdown' from Windows, and re-run this script."
  fi

  ok "installing nix (multi-user, upstream - not the Determinate fork)"
  if (( DRY )); then
    warn "would run the Determinate nix-installer"
  else
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
      | sh -s -- install linux --no-confirm
  fi
  nix_env
fi

if ! (( DRY )) && ! command -v nix >/dev/null; then
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
  if (( DRY )); then
    warn "would append auto-optimise-store to /etc/nix/nix.conf"
  else
    echo 'auto-optimise-store = true' | sudo tee -a /etc/nix/nix.conf >/dev/null
    sudo systemctl restart nix-daemon || warn "could not restart nix-daemon"
  fi
fi

# ---------------------------------------------------------------------------
# 4. pacman: the system half of the split
# ---------------------------------------------------------------------------
read_list() {
  # strips comments and blank lines
  [[ -f "$1" ]] || return 0
  sed -e 's/#.*$//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' "$1"
}

step "System packages (pacman)"

if (( ! DO_PACMAN )); then
  skip "--no-pacman given"
elif ! command -v pacman >/dev/null; then
  skip "pacman not found, not an Arch-based system"
else
  mapfile -t wanted < <(
    { read_list "$REPO/packages/common.txt"; read_list "$REPO/packages/$HOST.txt"; } | sort -u
  )

  missing=()
  for p in "${wanted[@]}"; do
    if ! pacman -Qq -- "$p" &>/dev/null; then
      missing+=("$p")
    fi
  done

  if (( ${#missing[@]} == 0 )); then
    ok "all ${#wanted[@]} declared system packages already installed"
  else
    ok "installing ${#missing[@]} missing: ${missing[*]}"
    # --needed makes this safe to repeat; AUR packages will fail here and need paru
    run sudo pacman -S --needed --noconfirm -- "${missing[@]}" \
      || warn "some packages failed - AUR entries (e.g. wsl2-ssh-agent) need: paru -S <pkg>"
  fi
fi

# ---------------------------------------------------------------------------
# 5. submodules (neovim config + the four zsh plugins)
#    zsh sources the plugins straight from the working tree, so this is no
#    longer cosmetic - an uninitialised submodule means no syntax highlighting,
#    no autosuggestions and no history substring search.
# ---------------------------------------------------------------------------
step "Submodules"

# `submodule status` prefixes uninitialised entries with '-'
if ! git -C "$REPO" submodule status --recursive 2>/dev/null | grep -q '^-'; then
  skip "all submodules already initialised"
else
  ok "initialising submodules"
  # .gitmodules uses SSH URLs. On a fresh machine there may be no key yet, so
  # rewrite to HTTPS just for this command rather than failing.
  run git -C "$REPO" \
    -c url."https://github.com/".insteadOf="git@github.com:" \
    submodule update --init --recursive \
    || warn "submodule init failed - zsh plugins will be missing until you run
       git -C ~/.mico submodule update --init --recursive"
fi

# ---------------------------------------------------------------------------
# 6. git identity (untracked, because this repo is public)
# ---------------------------------------------------------------------------
step "Git identity"

if [[ -f "$HOME/.gitconfig.local" ]] \
  && git config --file "$HOME/.gitconfig.local" --get user.email >/dev/null 2>&1; then
  skip "~/.gitconfig.local already has an identity"
elif (( DRY )); then
  warn "would prompt for git user.name and user.email"
elif (( ASSUME_YES )); then
  warn "no ~/.gitconfig.local and --yes given; set it later or commits will fail:"
  warn "  git config --file ~/.gitconfig.local user.name  '...'"
  warn "  git config --file ~/.gitconfig.local user.email '...'"
else
  read -r -p "  ? git user.name: " git_name
  read -r -p "  ? git user.email: " git_email
  if [[ -n "$git_name" && -n "$git_email" ]]; then
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

if (( ! DO_REMOVE )); then
  skip "--no-remove given"
elif ! command -v pacman >/dev/null; then
  skip "pacman not found"
else
  mapfile -t candidates < <(read_list "$REPO/packages/migrated.txt" | sort -u)

  present=()
  for p in "${candidates[@]}"; do
    # `cmd && arr+=(x)` as a bare statement returns 1 when cmd fails, which
    # `set -e` treats as fatal. if/then instead.
    if pacman -Qq -- "$p" &>/dev/null; then
      present+=("$p")
    fi
  done

  if (( ${#present[@]} == 0 )); then
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
# 9. user services
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

if [[ "$HOST" == "arch" ]]; then
  cat <<'EOF'
  kitty's font and theme are managed by this repo, so no manual font step is
  needed. If glyphs still look wrong, restart kitty so fontconfig is re-read.

EOF
fi
