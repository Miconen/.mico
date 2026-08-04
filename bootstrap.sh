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

read_list() {
  # strips comments and blank lines
  [[ -f "$1" ]] || return 0
  sed -e 's/#.*$//' -e '/^[[:space:]]*$/d' -e 's/[[:space:]]//g' "$1"
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
    --check)     CHECK_ONLY=1; shift ;;
    -h|--help)   sed -n '3,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
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

# ---------------------------------------------------------------------------
# --check: report drift between packages/*.txt and what pacman actually has.
# Read-only, needs no sudo, exits 1 if anything is out of sync. This is the
# useful half of the old backup-package-list timer, without the dump.
# ---------------------------------------------------------------------------
if (( CHECK_ONLY )); then
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
    local needle="$1"; shift
    local x
    for x in "$@"; do [[ "$x" == "$needle" ]] && return 0; done
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

  if (( ${#missing[@]} )); then
    drift=1
    warn "declared but NOT installed (${#missing[@]}):"
    printf '      %s\n' "${missing[@]}"
    printf '      fix: ./bootstrap.sh\n'
  else
    ok "all ${#declared[@]} declared packages are installed"
  fi

  if (( ${#dep_only[@]} )); then
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
  if (( ${#undeclared[@]} )); then
    drift=1
    warn "installed explicitly but NOT declared (${#undeclared[@]}):"
    printf '      %s\n' "${undeclared[@]}"
    printf '      fix: add to packages/%s.txt, or pacman -Rns / -D --asdeps\n' "$HOST"
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
  if (( ${#stale[@]} )); then
    drift=1
    warn "moved to nix but still installed via pacman (${#stale[@]}):"
    printf '      %s\n' "${stale[@]}"
    printf '      fix: ./bootstrap.sh   (it offers to remove them)\n'
  else
    ok "no migrated packages left on pacman"
  fi

  if (( drift )); then
    printf '\n%sdrift detected%s\n' "$C_YELLOW" "$C_RESET"
    exit 1
  fi
  printf '\n%sin sync%s\n' "$C_GREEN" "$C_RESET"
  exit 0
fi

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

# makepkg (and therefore paru) needs bash's `compgen`, which nixpkgs'
# non-interactive bash does not have: it is built with --disable-readline, and
# bash disables programmable completion along with readline. If such a bash wins
# on PATH, AUR builds fail with "compgen: command not found" inside fakeroot.
#
# The AUR phases below prepend /usr/bin to work around it, but warn here too,
# because the same trap catches any manual makepkg or paru run.
if [[ -n "${IN_NIX_SHELL:-}" ]]; then
  warn "running inside a nix shell (IN_NIX_SHELL=${IN_NIX_SHELL})."
  warn "its bash lacks compgen, which breaks makepkg. Prefer running this from a"
  warn "plain shell, or outside \$HOME/.mico if direnv loads the devShell there."
fi

bash_path="$(command -v bash || true)"
if [[ -n "$bash_path" && "$bash_path" != /usr/bin/bash && "$bash_path" != /bin/bash ]]; then
  warn "bash on PATH is $bash_path, not /usr/bin/bash"
  warn "if it came from nix it has no compgen and manual makepkg/paru will fail"
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
  dep_only=()
  for p in "${wanted[@]}"; do
    if ! pacman -Qq -- "$p" &>/dev/null; then
      missing+=("$p")
    elif ! pacman -Qqe -- "$p" &>/dev/null; then
      dep_only+=("$p")
    fi
  done

  if (( ${#missing[@]} == 0 )); then
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
  if (( ${#dep_only[@]} )); then
    ok "marking ${#dep_only[@]} dependency-only as explicit: ${dep_only[*]}"
    run sudo pacman -D --asexplicit -- "${dep_only[@]}" \
      || warn "could not update install reasons"
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

if (( ! DO_PACMAN )); then
  skip "--no-pacman given"
elif ! command -v pacman >/dev/null; then
  skip "pacman not found"
elif command -v paru >/dev/null; then
  skip "paru already installed ($(paru --version 2>/dev/null | head -1))"
elif (( DRY )); then
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
    if git clone --depth 1 "https://aur.archlinux.org/${AUR_HELPER_PKG}.git" "$aur_tmp/$AUR_HELPER_PKG" \
      && ( cd "$aur_tmp/$AUR_HELPER_PKG" \
           && PATH="/usr/bin:/usr/local/bin:$PATH" makepkg -si --noconfirm ); then
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

if (( ! DO_PACMAN )); then
  skip "--no-pacman given"
elif ! command -v pacman >/dev/null; then
  skip "pacman not found"
else
  mapfile -t aur_wanted < <(
    { read_list "$REPO/packages/aur-common.txt"; read_list "$REPO/packages/aur-$HOST.txt"; } | sort -u
  )

  aur_missing=()
  for p in "${aur_wanted[@]}"; do
    if ! pacman -Qq -- "$p" &>/dev/null; then
      aur_missing+=("$p")
    fi
  done

  if (( ${#aur_wanted[@]} == 0 )); then
    skip "no AUR packages declared"
  elif (( ${#aur_missing[@]} == 0 )); then
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
# 5. submodules (neovim config)
# ---------------------------------------------------------------------------
step "Submodules"

# `submodule status` prefixes uninitialised entries with '-'. Capture the output
# separately from the exit status: if git itself fails (dubious ownership, not a
# repo, ...) an empty result would otherwise look identical to "nothing to do"
# and we would silently skip initialising.
if ! sub_status="$(git -C "$REPO" submodule status --recursive 2>&1)"; then
  warn "could not read submodule status:"
  printf '      %s\n' "$sub_status"
  warn "run: git -C $REPO submodule update --init --recursive"
elif ! grep -q '^-' <<<"$sub_status"; then
  skip "all submodules already initialised"
else
  ok "initialising submodules"
  # .gitmodules uses SSH URLs. On a fresh machine there may be no key yet, so
  # rewrite to HTTPS just for this command rather than failing.
  run git -C "$REPO" \
    -c url."https://github.com/".insteadOf="git@github.com:" \
    submodule update --init --recursive \
    || warn "submodule init failed - run it manually once SSH keys are set up"
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
# 10. root/system profile garbage collection
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
elif [[ -f "$GC_TIMER" ]] && systemctl is-enabled nix-gc-system.timer &>/dev/null; then
  skip "nix-gc-system.timer already installed and enabled"
elif (( DRY )); then
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

if [[ "$HOST" == "arch" ]]; then
  cat <<'EOF'
  kitty's font and theme are managed by this repo, so no manual font step is
  needed. If glyphs still look wrong, restart kitty so fontconfig is re-read.

EOF
fi
