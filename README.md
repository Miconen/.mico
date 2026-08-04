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
bootstrap.sh              one-command machine setup, idempotent
flake.nix                 nixpkgs (unstable) + home-manager (master)
home/
  common.nix              packages, session vars, fonts, nvim symlink
  zsh.nix                 programs.zsh: history, options, plugins, aliases
  starship.nix            Catppuccin Powerline prompt
  git.nix                 programs.git + programs.delta
  fzf.nix                 fd integration, Catppuccin palette, completion helpers
  mise.nix                global node/python/go/rust + install activation hook
  tools.nix               bat, zoxide, direnv, keychain, verbatim configs
  nix-gc.nix              weekly GC user timer
hosts/
  arch.nix                laptop, incl. managed kitty config
  wsl.nix                 WSL (untested)
config/
  zellij/                 verbatim KDL
  tmux/tmux.conf          verbatim
  kitty/kitty.conf        verbatim, Maple Mono NF + Catppuccin
  bat/themes/             Catppuccin Mocha tmTheme
packages/
  common.txt              pacman packages for both hosts
  arch.txt                pacman packages, laptop only
  wsl.txt                 pacman packages, WSL only
  migrated.txt            pacman packages that moved to nix
.config/nvim              submodule -> Miconen/nvim
```

Not everything is expressed as Nix attributes. zellij's config is ~170 lines of
nested KDL keybindings; translating that into Nix would be unreadable and risk
silent breakage for no functional gain. Those files are managed verbatim via
`xdg.configFile` and are still fully reproducible.

---

## Bootstrap on a new machine

```sh
sudo pacman -S --needed git
git clone https://github.com/Miconen/.mico.git ~/.mico
~/.mico/bootstrap.sh
```

That is the whole thing. The script is **idempotent** - re-running it is the
intended way to apply changes to the system half of the setup, and every phase
detects whether it has already been done.

```
./bootstrap.sh                 auto-detect host, prompt before anything destructive
./bootstrap.sh --dry-run       print what would happen, change nothing
./bootstrap.sh --host wsl      override host detection
./bootstrap.sh --yes           unattended, no prompts
./bootstrap.sh --no-pacman     skip all pacman work
./bootstrap.sh --no-remove     install pacman packages but never remove any
```

Start with `--dry-run` on a machine you care about.

### What it does

| phase | action |
| --- | --- |
| Preflight | refuses to run as root, warns if the repo is not at `~/.mico`, warms the sudo timestamp once |
| Store location | if `/` is btrfs and `/nix` does not exist, creates a dedicated subvolume first |
| Nix | installs upstream Nix multi-user via `nix-installer`; on WSL, fails early with instructions if systemd is off |
| Daemon settings | appends `auto-optimise-store = true` to `/etc/nix/nix.conf`, which a flake cannot set |
| System packages | `pacman -S --needed` from `packages/common.txt` + `packages/<host>.txt` |
| Submodules | initialises the nvim submodule, rewriting SSH URLs to HTTPS so it works before you have keys |
| Git identity | prompts for name/email and writes `~/.gitconfig.local`, which is never committed |
| home-manager | activates `.#<host>`, which also installs the mise toolchains |
| Reconcile pacman | offers to remove `packages/migrated.txt` entries, **after** activation so the nix replacements already exist |
| User services | enables `podman.socket`, reports on `nix-gc.timer` |

Two design choices worth knowing:

- **pacman removal happens last, and asks.** Removing `git` before nix's `git`
  is on `PATH` would be an unpleasant way to discover an ordering bug. If pacman
  refuses because of dependencies, the script falls back to
  `pacman -D --asdeps`, which leaves the package installed but no longer
  explicitly wanted.
- **`mise install` is not in the script.** It is a home-manager activation hook
  in `home/mise.nix`, so it runs on every `hms` and there is nothing to
  remember. It is a fast no-op when everything is present, and non-fatal when
  offline. Skip it with `MICO_SKIP_MISE_INSTALL=1`.

### The system half is declarative too

`packages/*.txt` are inputs, not dumps of whatever happens to be installed:

| file | contents |
| --- | --- |
| `common.txt` | both hosts: base, `sudo`, `zsh` binary, `vim`/`nano` recovery editors, `openssh`, `podman` |
| `arch.txt` | laptop only: hyprland, plasma, sddm, pipewire, GPU drivers, kitty, firefox |
| `wsl.txt` | WSL only: `vulkan-dzn`, `wsl2-ssh-agent`, `paru` |
| `migrated.txt` | packages that moved to nix and should be removed from pacman |

Add a line, re-run `./bootstrap.sh`, done. AUR entries (`wsl2-ssh-agent`) still
need `paru -S` - plain pacman cannot fetch them, and the script warns rather
than failing.

### WSL prerequisites

Before running anything, on the Windows side in `/etc/wsl.conf`:

```ini
[boot]
systemd=true
```

Required - the multi-user nix daemon cannot run without it. Optionally:

```ini
[interop]
appendWindowsPath=false
```

Stops Windows `PATH` entries from shadowing nix binaries, at the cost of losing
`code` and `explorer.exe` from the shell. Then `wsl --shutdown`.

### Validating before you activate

If you would rather not let the script activate blindly, do the switch by hand:

```sh
cd ~/.mico
nix eval .#homeConfigurations.arch.activationPackage.drvPath   # evaluates
nix build .#homeConfigurations.arch.activationPackage --no-link  # builds
./bootstrap.sh --no-remove
```

`nix eval` catches bad option names; `nix build` catches build-time failures
that evaluation cannot see, such as the starship preset lookup and
`bat cache --build`.

---

## Verifying an activation

Run this as a block. No inline comments - `interactive_comments` is enabled by
this config, but the very first shell after a fresh install may predate it.

```sh
which -a git eza zoxide lazygit nvim starship mise
echo "$ZSH_AUTOSUGGEST_STRATEGY"
bindkey '^[[A'
git config --get merge.conflictstyle
git config --get core.pager
git config --get user.email
readlink -f ~/.config/nvim
fc-list | grep -ci maple
mise ls
```

Expected:

| check | expected |
| --- | --- |
| `which -a` | `~/.nix-profile/bin/...` listed **first** |
| `ZSH_AUTOSUGGEST_STRATEGY` | `history completion` |
| `bindkey '^[[A'` | `history-substring-search-up` |
| `merge.conflictstyle` | `zdiff3` |
| `core.pager` | a `delta` store path |
| `user.email` | whatever is in `~/.gitconfig.local` |
| `readlink -f ~/.config/nvim` | `/home/miso/.mico/.config/nvim` |
| `fc-list \| grep -ci maple` | non-zero |
| `mise ls` | no `(missing)` entries |

Use `readlink -f`, not plain `readlink`. home-manager points
`~/.config/nvim` at a symlink inside `home-manager-files` in the store, and
*that* points at the working tree. Plain `readlink` shows only the first hop and
looks alarmingly like an immutable store path when it isn't one.

The plugin checks matter because home-manager sources plugins with
`[[ -f ... ]] && source`, so a wrong path fails **silently** - no error, the
widgets just don't exist and `bindkey` quietly binds nothing.

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

## Editing this config

```sh
nvim ~/.mico/home/zsh.nix   # or the `zshconf` alias
hms                         # switch
exec zsh                    # reload the current shell
```

Three things to know:

1. **Flakes read the git tree, and untracked files are silently excluded.**
   Editing an already-tracked file works uncommitted - you just get a harmless
   `warning: Git tree ... is dirty`. But when you *add* a file you must
   `git add` it, or your change will appear to do nothing.

2. **`exec zsh` is safe inside zellij, not outside it.** `initContent` at order
   500 execs zellij whenever `$ZELLIJ` is unset. Inside a pane the guard skips
   and you get a fresh shell; in a bare terminal you get a multiplexer.

3. **Keep a second terminal open while editing `zsh.nix`.** It is the one file
   where a mistake can leave you without a working shell.

### Seeing the result without switching

This prints the fully merged, order-resolved `.zshrc`, which is the only
reliable way to confirm `lib.mkOrder` placed something where you expected:

```sh
nix eval --raw .#homeConfigurations.arch.config.programs.zsh.initContent | less
```

Inspecting individual values:

```sh
nix eval .#homeConfigurations.arch.config.programs.zsh.shellAliases.ls
nix eval .#homeConfigurations.arch.config.home.packages --apply 'map (p: p.name)'
```

Building without activating, which catches build-time failures that `nix eval`
cannot see (the starship preset lookup and the `bat cache --build` step):

```sh
nix build .#homeConfigurations.arch.activationPackage --no-link
```

### Order slots used by home-manager

When adding to `initContent`, these are already taken upstream, so pick a slot
deliberately rather than reusing one:

| order | what |
| --- | --- |
| 500 | `mkBefore`, earliest - zellij autostart lives here |
| 510-540 | path/fpath setup, local variables |
| 560 | plugin dirs added to `fpath` |
| 570 | `compinit` |
| 900 | plugin sourcing |
| 1000 | default - general config |
| 1100 | `shellAliases` |
| 1150 | directory hashes |
| 1200 | syntax highlighting |
| 1300 | fzf completion helpers (this repo) |
| 1500 | `mkAfter`, last - keybindings must go here, after plugins define widgets |

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
