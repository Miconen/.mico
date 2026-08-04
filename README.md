# .mico

Home-manager flake for `miso`. Arch laptop + Arch on WSL.

Nix owns CLI tools and configs. Pacman owns the kernel, drivers, desktop, GUI,
`gcc`/`base-devel`, the `zsh` binary, `vim`/`nano`, `openssh` and `podman`. AUR
packages go through paru, declared in `packages/aur-*.txt`.
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
--check       report pacman drift and exit, read-only, no sudo
--dry-run     change nothing, just print
--host wsl    override host detection
--yes         no prompts
--no-pacman   skip pacman entirely
--no-remove   install pacman packages, never remove any
```

It does: btrfs subvolume for `/nix` → install nix → `auto-optimise-store` →
pacman sync → pacman.conf → build paru → AUR sync → submodules →
`~/.gitconfig.local` → `home-manager switch` → remove pacman packages nix
replaced → `podman.socket` → system maintenance timers → root-level GC timer.

The maintenance timers are all off by default on Arch: `fstrim.timer` (SSD TRIM),
`btrfs-scrub@-.timer` (monthly checksum scrub of `/` — btrfs stores checksums but
never verifies them unless scrubbed), `smartd`, `paccache.timer`, and
`reflector.timer`.

AUR packages are separate because `pacman -S` cannot install them. paru itself is
AUR-only, so it is not installable by an AUR helper or by pacman — bootstrap
builds `paru-bin` with `makepkg` once, then uses paru for the rest.
`paru-bin` rather than `paru` avoids dragging a Rust toolchain onto every
machine.

`--check` audits pacman against `packages/*.txt` and exits 1 on drift. Run it when
you suspect you `pacman -S`’d something and forgot. It reports four states:
not installed, installed only as a dependency (a declaration is not really
satisfied until the install reason is explicit, since a dependency can be removed
with its parent), explicitly installed but undeclared, and migrated-to-nix but
still present:

```bash
~/.mico/bootstrap.sh --check
```

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
hms                              # nh home switch + syntax check + exec zsh
nix flake update                 # bump nixpkgs + home-manager, then hms
git submodule update --remote    # bump nvim, then hms
home-manager generations         # list rollback targets
, cowsay hi                      # run a package without installing it
nix-locate bin/ffmpeg            # which package provides this file
nix shell nixpkgs#foo            # one-off shell, not persisted
```

`hms` runs `nh home switch`, which prints a package diff of what changed, then
`zsh -n ~/.zshrc` before `exec zsh`. That guard matters: activation can succeed
while writing a `.zshrc` that does not parse, since home-manager never parses the
zsh it generates.

Editing:

```bash
zshconf                          # opens home/zsh.nix
nixconf                          # opens flake.nix
hms && exec zsh
```

`git add` new files before switching — flakes read the git tree and **silently
ignore untracked files**. Editing tracked files uncommitted is fine.

Working on the repo itself:

```bash
direnv allow            # once; loads nixfmt, statix, deadnix from the devShell
nix fmt                 # format all .nix
nix flake check         # builds BOTH hosts
```

CI builds both hosts on every push. Lint runs via `ci/lint.sh`, which also works
locally:

```bash
./ci/lint.sh      # nixfmt --check, statix, deadnix
```

Lint is advisory while `continue-on-error: true` is set on that job in
`.github/workflows/build.yml`. Remove it to make lint blocking.

`statix.toml` disables `repeated_keys` and `empty_pattern` — both are sensible
for ordinary Nix but wrong for module files, where flat `programs.foo.bar = ...`
and a `{ ... }:` signature are the convention.

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

## zellij

```
Ctrl-g   lock / unlock (pass keys through to the terminal)
Ctrl-p   pane      Ctrl-t   tab       Ctrl-n   resize
Ctrl-s   scroll    Ctrl-m   move      Ctrl-o   session
Alt-d    detach            Ctrl-q   quit (DESTROYS the session)
Alt-[ / Alt-]     cycle swap layouts
Alt-h/j/k/l       move focus        Alt-n   new pane
zt                jump to / create a tab named after the current project
```

Session mode (`Ctrl-o`): `d` detach, `w` session manager, `l` layout manager,
`c` configuration, `p` plugin manager, `a` about.

**Detach, do not quit.** `Alt-d` leaves the session running so
`session_serialization` can resurrect its panes and cwds; `Ctrl-q` tears it down.
The config had no detach binding at all until recently, because
`clear-defaults=true` drops zellij's whole `session` mode along with it.

`ZELLIJ_SKIP=1` starts a shell without attaching, for when you need a bare shell.

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

**No hardware video decode.** This laptop is an AMD Carrizo APU, but the old
package set installed only Intel VA-API drivers. `mesa` is now the VA-API
provider (it `replaces libva-mesa-driver`). One-time cleanup of the leftovers:

```bash
sudo pacman -Rns vulkan-intel vulkan-nouveau intel-media-driver \
  libva-intel-driver xf86-video-nouveau xf86-video-ati
sudo pacman -S --asexplicit mesa
vainfo   # expect radeonsi entries; needs libva-utils
```

`bootstrap.sh --check` reports these as installed-but-undeclared, but never
removes undeclared packages automatically.

**Which Nix is this?** `install.determinate.systems` installs *Determinate Nix*,
not upstream — `nix --version` reports e.g. `nix (Determinate Nix 3.21.9) 2.34.8`.
The `--determinate` flag toggles enterprise features and does **not** select the
distribution, so omitting it does not get you upstream. Everything here works
identically on either; use the nixos.org installer if you want strictly upstream.

**`compgen: command not found` during an AUR build.** nixpkgs’ non-interactive
`bash` is built with `--disable-readline`, which also disables programmable
completion — so it has no `compgen`, and makepkg’s `config.sh` dies inside
fakeroot. Happens when a nix `bash` wins on PATH, most easily by running things
from `~/.mico` while direnv has the devShell loaded.

```bash
readlink -f "$(command -v bash)"   # expect /usr/bin/bash
```

Resolve the symlink rather than reading `which -a` directly: `.envrc` shadows
`bash` with `.direnv/bin/bash`, which points at `/usr/bin/bash`, so the raw path
looks wrong while being correct. `IN_NIX_SHELL=impure` inside this repo is
expected and fine.

Three layers guard against it: `.envrc` shadows `bash` with `/usr/bin/bash` via
`.direnv/bin`, `bootstrap.sh` prepends `/usr/bin` for makepkg and paru, and
preflight warns if `bash` still resolves elsewhere. For a manual build outside
all of that:

```bash
PATH=/usr/bin:$PATH makepkg -si
```

**`pacman -Rns git` refuses.** Something depends on it.
`sudo pacman -D --asdeps git` instead.

**Don't** put `gcc` in the nix profile (breaks `makepkg`), make `zsh` a nix
package (a store login shell can lock you out after GC), or use
`nix profile install` (invisible to this repo, drifts between machines).

## Gotchas worth knowing

- `programs.eza` is not enabled on purpose — its zsh integration defines
  `shellAliases.ls` and collides with ours, which fails evaluation outright.
- User GC is `nix.gc.automatic`. The options live under `nix.gc.*` but are
  declared in `modules/services/nix-gc.nix` upstream, which is easy to miss when
  searching by file path. Upstream only collects the *current user's* profiles, so
  the root/system profile has a separate `/etc/systemd/system` timer written by
  `bootstrap.sh` — and that one does **not** roll back with a generation.
- `auto-optimise-store` is a daemon setting needing root, so `bootstrap.sh` does it.
- `mise install` runs on every `hms` as an activation hook. Skip with
  `MICO_SKIP_MISE_INSTALL=1`.
- **Ctrl-R is atuin**, not fzf. fzf's history widget is deliberately blanked
  (`historyWidget.command = ""`), which is the documented way to hand Ctrl-R to a
  history manager. Up/Down stay on zsh-history-substring-search via
  `--disable-up-arrow`.
- **Tab completion is fzf-tab.** It is sourced at `initContent` order 600, which
  is deliberate: after compinit (570) but before home-manager sources
  zsh-autosuggestions (700). Declaring it under `programs.zsh.plugins` would put
  it at 900 and it would silently do nothing.
- Atuin history is local-only. Do **not** sync `~/.local/share/atuin` with
  Syncthing or similar — it is a live SQLite database and file-syncing corrupts
  it. Use atuin's own encrypted sync if you want cross-machine history.
- `~/.zshrc` is a read-only store symlink. Editing it does nothing.
- `dotDir` is pinned to `$HOME`; the default moves to `$XDG_CONFIG_HOME/zsh` at
  stateVersion 26.05.
- Nothing secret goes in this repo, it's public. Git identity lives in untracked
  `~/.gitconfig.local`.
- zellij runs one persistent session named `main`. A wedged session follows you
  between terminals until `zellij kill-session main`.
- `hosts/wsl.nix` is built by CI but otherwise untested — CI proves it compiles,
  not that wsl2-ssh-agent or the clipboard fallbacks work.

## Layout

```
.github/workflows/   CI: builds both hosts on push
ci/lint.sh           lint runner, works locally too
statix.toml          lint exclusions that clash with module conventions
bootstrap.sh         machine setup, --check audits pacman drift
flake.nix            nixpkgs unstable + home-manager master, devShell, checks
home/                zsh, starship, git, fzf, mise, tools
hosts/               arch.nix, wsl.nix
config/              verbatim: zellij, kitty, bat theme
packages/            repo lists: common, arch, wsl, migrated
                     AUR lists: aur-common, aur-arch, aur-wsl
.config/nvim         submodule → Miconen/nvim
```
