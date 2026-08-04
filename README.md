# .mico

Home-manager flake for `miso`. Arch laptop + Arch on WSL.

Nix owns CLI tools and configs. Pacman owns the kernel, drivers, desktop, GUI,
`gcc`/`base-devel`, the `zsh` binary, `vim`/`nano`, `openssh` and `podman`.
Neovim config lives in its own repo as a submodule.

## Install

```bash
sudo pacman -S --needed git
git clone https://github.com/Miconen/.mico.git ~/.mico
~/.mico/bootstrap.sh
```

Idempotent — re-run it after editing `packages/*.txt`. Use `--dry-run` first on a
machine you care about.

```
--dry-run     change nothing, just print
--host wsl    override host detection
--yes         no prompts
--no-pacman   skip pacman entirely
--no-remove   install pacman packages, never remove any
```

It does: btrfs subvolume for `/nix` → install nix → `auto-optimise-store` →
pacman sync → submodules → `~/.gitconfig.local` → `home-manager switch` →
remove pacman packages nix replaced → enable `podman.socket`.

### WSL first

`/etc/wsl.conf` on the Windows side, then `wsl --shutdown`:

```ini
[boot]
systemd=true

[interop]
appendWindowsPath=false
```

`systemd=true` is mandatory, the nix daemon needs it. `appendWindowsPath=false`
stops Windows PATH shadowing nix binaries, but costs you `code` and
`explorer.exe` in the shell.

## Daily

```bash
hms                              # switch (alias, host-correct)
nix flake update                 # bump nixpkgs + home-manager, then hms
git submodule update --remote    # bump nvim, then hms
home-manager generations         # list rollback targets
nix shell nixpkgs#foo            # one-off, not persisted
```

Editing:

```bash
zshconf                          # opens home/zsh.nix
nixconf                          # opens flake.nix
hms && exec zsh
```

`git add` new files before switching — flakes read the git tree and **silently
ignore untracked files**. Editing tracked files uncommitted is fine.

Preview without switching:

```bash
nix eval --raw .#homeConfigurations.arch.config.programs.zsh.initContent | less
nix build .#homeConfigurations.arch.activationPackage --no-link
```

`nix eval` catches bad option names, `nix build` catches build failures eval
can't see (starship presets, `bat cache --build`).

## Verify an activation

```bash
which -a git eza zoxide lazygit nvim starship
echo "$ZSH_AUTOSUGGEST_STRATEGY"
bindkey '^[[A'
git config --get merge.conflictstyle
git config --get user.email
readlink -f ~/.config/nvim
fc-list | grep -ci maple
mise ls
```

Want: nix paths first, `history completion`, `history-substring-search-up`,
`zdiff3`, your email, `/home/miso/.mico/.config/nvim`, non-zero, no `(missing)`.

## Fixes

**Plugins silently don't load.** home-manager sources them with
`[[ -f ]] && source` — a wrong `file` path produces no error at all. If
`bindkey '^[[A'` prints nothing, the path in `programs.zsh.plugins` is wrong.

**`readlink ~/.config/nvim` shows a store path.** Expected. It's a chain:
`~/.config/nvim` → store symlink → working tree. Use `readlink -f`.

**Neovim has no config.** Submodule wasn't initialised.
`git -C ~/.mico submodule update --init --recursive`. Activation warns about
this.

**`nix` not found after install.** Arch builds zsh with `--enable-etcdir=/etc/zsh`,
so the installer's `/etc/zshrc` hook is ignored. Login shells still work via
`/etc/zsh/zprofile` → `/etc/profile` → `/etc/profile.d/nix.sh`. For the current
shell: `. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`

**Broken shell after a switch.**

```bash
home-manager generations
/nix/store/<hash>-home-manager-generation/activate
```

Keep a second terminal open while editing `zsh.nix`.

**Prompt glyphs are tofu.** kitty needs `Maple Mono NF`, which this repo already
sets. Restart kitty so fontconfig is re-read.

**`ls` errors on a filename.** eza wants `--icons=always`, with the `=`. Space
separated makes the value a path argument.

**Clipboard does nothing in WSL.** `pbcopy`/`pbpaste` prefer WSLg's
`wl-copy`/`wl-paste` and fall back to `clip.exe`/`powershell.exe` by absolute
path, since `appendWindowsPath=false` takes them off PATH. Neovim autodetects
wl-clipboard when `WAYLAND_DISPLAY` is set; without WSLg, point `g:clipboard` at
`pbcopy`/`pbpaste`.

**`pacman -Rns git` refuses.** Something depends on it.
`sudo pacman -D --asdeps git` instead.

**Don't** put `gcc` in the nix profile (breaks `makepkg`), make `zsh` a nix
package (a store login shell can lock you out after GC), or use
`nix profile install` (invisible to this repo, drifts between machines).

## Gotchas worth knowing

- `programs.eza` is not enabled on purpose — its zsh integration defines
  `shellAliases.ls` and collides with ours, which fails evaluation outright.
- home-manager has no `nix.gc` option, so GC is a user timer in `home/nix-gc.nix`.
- `auto-optimise-store` is a daemon setting needing root, so `bootstrap.sh` does it.
- `mise install` runs on every `hms` as an activation hook. Skip with
  `MICO_SKIP_MISE_INSTALL=1`.
- `~/.zshrc` is a read-only store symlink. Editing it does nothing.
- `fastfetch` runs in every interactive shell, so every zellij pane.
- `dotDir` is pinned to `$HOME`; the default moves to `$XDG_CONFIG_HOME/zsh` at
  stateVersion 26.05.
- Nothing secret goes in this repo, it's public. Git identity lives in untracked
  `~/.gitconfig.local`.
- `hosts/wsl.nix` is untested.

## Layout

```
bootstrap.sh         machine setup
flake.nix            nixpkgs unstable + home-manager master
home/                zsh, starship, git, fzf, mise, tools, nix-gc
hosts/               arch.nix, wsl.nix
config/              verbatim: zellij, tmux, kitty, bat theme
packages/            pacman lists: common, arch, wsl, migrated
.config/nvim         submodule → Miconen/nvim
```
