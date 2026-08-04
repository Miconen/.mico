# .mico

Declarative user environment for `miso`, shared between an Arch Linux laptop and
Arch on WSL. Nix + home-manager own user-space tooling and configuration; pacman
owns the system.

This repo used to be a GNU Stow dotfiles tree. It is now a home-manager flake.
The only thing still managed as a plain tree is the neovim config, which remains
a submodule.

---

## The split rule

The single most important convention in this repo. When you wonder "should this
be nix or pacman?", this is the answer.

| pacman owns | nix owns |
| --- | --- |
| kernel, firmware, microcode, drivers (`vulkan-*`, `xf86-video-*`, `intel-media-driver`) | every CLI tool |
| desktop: `hyprland`, `plasma-meta`, `sddm`, `uwsm`, `dunst`, `wofi`, `kitty` | shell config, prompt, aliases |
| audio/network/print: `pipewire`, `networkmanager`, `bluez`, `cups` | language runtimes, via `mise` |
| build toolchain: `gcc`, `base-devel` | terminal font (`maple-mono.NF`) |
| the `zsh` **binary** | zsh **configuration** |
| recovery editors: `vim`, `nano` | `neovim` the binary |
| system services: `openssh`, `podman` | container **clients**, aliases, `DOCKER_HOST` |
| `paru`, `archinstall` | |

Two rules that follow from this:

1. **Never put `gcc` in the home-manager profile.** It shadows the system
   compiler and breaks `makepkg` and header resolution on Arch.
2. **Never make `zsh` a nix package.** A `/nix/store` login shell can lock you
   out of your account after a garbage collection or a failed activation.

GUI applications are never installed via nix here. On a non-NixOS system they
need `XDG_DATA_DIRS` wiring for `.desktop` files and `nixGL` wrappers for
hardware acceleration, which is a large maintenance burden when pacman and
flatpak already have those apps.

**Nothing imperative.** `nix profile install` creates state this repo cannot
see, which silently drifts between machines. Use `nix shell nixpkgs#foo` for
one-off throwaway use; anything permanent goes in `home/common.nix`.

**No secrets.** This repo is public. Git identity lives in an untracked
`~/.gitconfig.local`. If secrets are ever needed, that is a `sops-nix` /
`agenix` conversation, not a "just this once" one.

---

## Layout

```
flake.nix                 nixpkgs (unstable) + home-manager (master)
home/
  common.nix              packages, session vars, fonts, nvim symlink
  zsh.nix                 programs.zsh: history, options, plugins, aliases
  starship.nix            Catppuccin Powerline prompt
  git.nix                 programs.git
  fzf.nix                 fd integration, Catppuccin palette, completion helpers
  mise.nix                global node/python/go/rust
  tools.nix               bat, zoxide, direnv, keychain, verbatim configs
  nix-gc.nix              weekly GC user timer
hosts/
  arch.nix                laptop
  wsl.nix                 WSL (untested)
config/
  zellij/                 verbatim KDL
  tmux/tmux.conf          verbatim
  bat/themes/             Catppuccin Mocha tmTheme
.config/nvim              submodule -> Miconen/nvim
```

Not everything is expressed as Nix attributes. zellij's config is ~170 lines of
nested KDL keybindings; translating that into Nix would be unreadable and risk
silent breakage for no functional gain. Those files are managed verbatim via
`xdg.configFile` and are still fully reproducible.

---

## Bootstrap on a new machine

### 0. WSL only

In `/etc/wsl.conf` on the Windows side:

```ini
[boot]
systemd=true
```

`systemd=true` is **required** — the multi-user nix daemon cannot run without
it. Optionally add:

```ini
[interop]
appendWindowsPath=false
```

This stops Windows `PATH` entries from shadowing nix binaries, at the cost of
losing `code`, `explorer.exe` etc. from the shell. Then `wsl --shutdown`.

### 1. Arch laptop only: give `/nix` its own btrfs subvolume

Root is btrfs (subvolume `@`). Do this **before** installing nix, or you will be
moving the whole store later:

```sh
sudo btrfs subvolume create /nix
```

btrfs snapshots are not recursive, so a nested subvolume keeps the store — which
grows to many GB on unstable — out of any root snapshots. WSL uses ext4 in a
VHDX and has no subvolumes, so it skips this step entirely.

### 2. Install Nix

```sh
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
  | sh -s -- install linux --no-confirm
```

Do **not** pass `--determinate`; that installs Determinate's fork rather than
upstream Nix.

Verify:

```sh
systemctl status nix-daemon.socket
grep experimental-features /etc/nix/nix.conf   # expect: nix-command flakes
ls /etc/profile.d/nix.sh
```

> **Arch note.** The installer writes a hook to `/etc/zshrc`, which Arch's zsh
> never reads — Arch builds zsh with `--enable-etcdir=/etc/zsh`. Login shells
> still work because Arch's `/etc/zsh/zprofile` sources `/etc/profile`, which
> sources `/etc/profile.d/nix.sh`. If `nix` is not found, source it manually for
> the current shell:
>
> ```sh
> . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
> ```

### 3. Enable store deduplication (needs root, cannot be done from this flake)

```sh
echo 'auto-optimise-store = true' | sudo tee -a /etc/nix/nix.conf
sudo systemctl restart nix-daemon
```

Garbage collection itself is handled by the `nix-gc` user timer in this repo.

### 4. Get the repo

If `~/.mico` already exists and is stowed, **unstow first, while the old files
are still present**:

```sh
cd ~/.mico
stow -D .          # removes the symlinks this repo used to create
git fetch origin
git checkout main  # or the migration branch
git submodule update --init --recursive
```

Order matters. Checking out the new tree before unstowing leaves dangling
symlinks in `$HOME` that home-manager then has to fight.

On a genuinely new machine:

```sh
git clone --recursive git@github.com:Miconen/.mico.git ~/.mico
```

### 5. Validate before activating

Flakes only see git-tracked files, so commit or `git add` anything new first.
This forces full module evaluation without building, which catches bad option
names immediately:

```sh
cd ~/.mico
nix eval .#homeConfigurations.arch.activationPackage.drvPath
```

### 6. Activate

```sh
nix run github:nix-community/home-manager -- switch --flake ~/.mico#arch -b backup
```

Use `#wsl` on WSL. `-b backup` renames anything that would be clobbered instead
of failing.

**Open a new terminal and confirm it works before closing the old one.** This is
the step that can leave you without a usable shell.

### 7. Remove the pacman duplicates

Only after verifying that `which -a git eza zoxide lazygit neovim` resolve into
`~/.nix-profile/bin`:

```sh
sudo pacman -Rns eza fastfetch git htop keychain lazygit neovim wget zoxide
```

If pacman refuses because something depends on `git`, demote it instead of
removing:

```sh
sudo pacman -D --asdeps git
```

Then add what pacman should still own explicitly:

```sh
sudo pacman -S --asexplicit openssh podman
systemctl --user enable --now podman.socket   # for DOCKER_HOST
```

### 8. Set your git identity (untracked, per machine)

```sh
git config --file ~/.gitconfig.local user.name  "Miconen"
git config --file ~/.gitconfig.local user.email "you@example.com"
```

### 9. Set the terminal font

The Catppuccin Powerline prompt needs a Nerd Font. `maple-mono.NF` is installed
by this flake and exposed through fontconfig, so point kitty at it:

```conf
font_family Maple Mono NF
```

---

## Day-to-day

```sh
hms                        # home-manager switch, host-correct (alias)
nix flake update           # bump nixpkgs/home-manager, then hms
nix flake update nixpkgs   # bump just one input
home-manager generations   # list previous generations
nix shell nixpkgs#foo      # one-off tool, not persisted
```

Rolling back a bad activation:

```sh
home-manager generations           # find the previous one
/nix/store/<hash>-home-manager-generation/activate
```

`flake.lock` is the pin. Nothing changes version until you run
`nix flake update`, even though the inputs track unstable.

---

## Changes from the old stow setup

Fixed along the way:

- `alias fd='fdfind'` and `alias bat='batcat'` were Debian-only binary names and
  were broken on Arch. Removed; the real names work everywhere now.
- `.gitconfig` had two silent typos: `conflicstyle` (so zdiff3 was never active)
  and `sudmodule`. Git discards unknown keys without error.
- The Windows Git credential helper was set unconditionally and was broken on
  the laptop. Now WSL-only.
- `exec zellij` had no interactivity guard, so `zsh -i -c` and remote commands
  would spawn a multiplexer. Now guarded on `-o interactive`, `$ZELLIJ`,
  `$SSH_CONNECTION` and `TERM != dumb`.
- `clear; fastfetch` was unreachable whenever zellij actually worked, because
  `exec` had already replaced the shell. The greeting now runs inside the
  session.
- `DOCKER_HOST` pointed at a podman socket on a machine with no podman.
- `$(go env GOPATH)` spawned a go process on every shell start.
- `HISTSIZE`/`SAVEHIST` were 1000.
- `source /etc/environment` was dropped; it is not shell syntax and is fragile.

Removed:

- **nvm** (sourced twice, from `$NVM_DIR` and `/usr/share/nvm`) and **rustup**
  via `~/.cargo/env`. Both fought mise for `PATH`. mise now owns node, python,
  go and rust.
- **powerlevel10k** submodule and `.p10k.zsh`, replaced by starship.
- Four zsh plugin submodules, replaced by nixpkgs packages. Note that
  home-manager has no `historySubstringSearch` option, so that one is wired up
  as an explicit `programs.zsh.plugins` entry.
- The `backup-package-list` service, timer and script, plus
  `packages/packages.txt`. This flake is the source of truth now.
- The unused `tokyo-night` zellij themes.

---

## Things that surprise people

- **`programs.eza` is deliberately not enabled.** Its zsh integration defines
  `shellAliases.ls = "eza"`, which collides with the richer `ls` alias in
  `home/zsh.nix` and makes evaluation fail outright. eza is a plain package.
- **home-manager has no `nix.gc` option** — there is no `modules/misc/nix.nix`
  at all. GC is a hand-written user timer in `home/nix-gc.nix`.
- **`auto-optimise-store` cannot be set from here.** It is a daemon setting and
  needs root, hence the manual step above.
- **`~/.zshrc` is a read-only store symlink now.** Editing it does nothing. Use
  the `zshconf` alias, which opens `home/zsh.nix`.
- **fastfetch runs in every interactive shell**, which means every new zellij
  pane. Comment it out in `home/zsh.nix` if that gets noisy.
- **`dotDir` is pinned explicitly** to the home directory. At
  `stateVersion = "26.05"` the default moves to `$XDG_CONFIG_HOME/zsh`, which
  would relocate the config and require `ZDOTDIR` indirection.
