# mico

Your Arch laptop and Arch-on-WSL, as a git repo. You forgot how this works.
That is fine. You almost never need the internals.

Nix owns CLI tools and their configs. Pacman owns the kernel, drivers, desktop,
GUI, `gcc`/`base-devel`, the `zsh` binary, `vim`/`nano`, `openssh`, and `podman`.
AUR packages go in `packages/aur-*.txt` and get installed by paru.

After the first switch, `mico` is on PATH everywhere.

```
mico switch              apply nix home config          (used to be hms)
mico update              bump flake.lock, then switch
mico bootstrap           first boot / re-run machine setup
mico install             open packages/ in nvim
mico install mesa        add to packages/common.txt, then bootstrap
mico check               report pacman drift, change nothing
mico lint                format and lint this repo
```

`hms` still works. It is just `mico switch`.

## First time

```bash
sudo pacman -S --needed git
git clone https://github.com/Miconen/.mico.git ~/.mico
~/.mico/bootstrap.sh
```

Safe to re-run. Use `--dry-run` on a machine you care about.

On WSL, put this in `/etc/wsl.conf` on the Windows side, then `wsl --shutdown`:

```ini
[boot]
systemd=true

[interop]
appendWindowsPath=false
```

systemd is mandatory. The nix daemon needs it. Turning off Windows PATH stops
`code.exe` from shadowing nix binaries. You lose `code` and `explorer.exe` in
the shell. That is the trade.

Until the first successful switch, there is no `mico` on PATH. Run
`~/.mico/bootstrap.sh` (or `~/.mico/scripts/mico bootstrap`) once, then forget
the path.

## Adding a package

Try it first. Nothing gets installed.

```bash
, cowsay hello              # one-off from nixpkgs
nsearch ripgrep             # search nixpkgs
nwhich bin/ffmpeg           # which package provides this binary
```

Want to keep it? It depends what it is.

**CLI tool.** Open `home/common.nix` (`pkgconf`) and add a line to
`home.packages`. If home-manager has a `programs.*` module for it, use that
instead. The module also owns the config, which is why btop settings survive a
new machine and a first-run `btop.conf` does not. Then:

```bash
mico switch
```

**System / GUI / kernel thing.**

```bash
mico install mesa                 # packages/common.txt, both machines
mico install --local hyprland     # packages/arch.txt or wsl.txt
mico install --aur something      # packages/aur-common.txt
mico install                      # just open the folder in nvim
```

That writes the list, then runs bootstrap so pacman/paru actually install it.

Two rules you will break if you are tired:

- Never `nix profile install`. Invisible to this repo. Drifts between machines.
- Never put `gcc` or `zsh` in the nix profile. gcc shadows pacman's and breaks
  makepkg. A store login shell can lock you out after GC.

New files under `home/` need `git add` before switch. Flakes silently ignore
untracked files. Editing an already-tracked file without committing is fine.

## Daily

```bash
mico switch                 # apply home.nix changes
mico update                 # flake.lock + switch
mico bootstrap              # pacman/AUR + the rest of machine setup
mico check                  # did you pacman -S something and forget?
mico lint                   # before a push, or whenever
```

`mico switch` prints a package diff, syntax-checks `~/.zshrc`, then execs zsh.
That last bit matters. home-manager will happily write a `.zshrc` that does not
parse.

```bash
zshconf                     # home/zsh.nix
nixconf                     # flake.nix
pkgconf                     # home/common.nix
```

`nix flake check` builds both hosts. CI does the same on every push.

## Neovim

Config is `.config/nvim` in this repo. `~/.config/nvim` is an out-of-store
symlink into the working tree, because lazy.nvim writes `lazy-lock.json` and a
store path is read-only. Plugin updates show up as a dirty lockfile. Commit it.

After pulling a commit that moves the lockfile, `:Lazy restore` then `:TSUpdate`.
Mismatched treesitter parsers crash highlighting. This is not optional.

## Zellij

Mode entry is Alt, not Ctrl. Globally, zellij only eats Ctrl-g and Ctrl-q.

```
Alt-p    pane      Alt-t    tab       Alt-r    resize
Alt-s    scroll    Alt-m    move
Alt-d    detach    Alt-n    new pane  Alt-h/j/k/l  move focus
Ctrl-g   lock               Ctrl-q    quit (kills the session)
```

Config changes need a new session. zellij reads config when the server starts,
and `session_serialization` resurrects the old layout on attach. `mico switch`
alone re-execs zsh *inside* the existing session and looks like a no-op.

```bash
zreload                     # delete the `main` session
```

The terminal closes. Open a new one.

## Syncthing

Laptop only. Pairing is declarative in `hosts/arch.nix`. Do not accept devices
or folders in the web UI. `overrideDevices` / `overrideFolders` delete anything
you click on the next switch.

GUI is `http://127.0.0.1:8384`. Localhost only, no password, which is why no
secret lives in this public repo.

This machine's own device ID does not need declaring. Get it with
`syncthing device-id` if a phone or the desktop needs it.

## When it breaks

**Broken shell after a switch.** Keep a second terminal open while editing
`zsh.nix`. Roll back with:

```bash
home-manager generations
/nix/store/<hash>-home-manager-generation/activate
```

**`nix` not found.** Current shell: `. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh`

**`compgen: command not found` during an AUR build.** A nix bash won on PATH.
`readlink -f "$(command -v bash)"` should be `/usr/bin/bash`. If not:
`PATH=/usr/bin:$PATH makepkg -si`

**`--check` reports a `*-debug` package.** `sudo pacman -Rns paru-bin-debug`

**Clipboard does nothing in WSL.** `pbcopy`/`pbpaste` are the wrappers. They
prefer WSLg, then fall back to `clip.exe`.

**Prompt glyphs are tofu.** Restart kitty. It already has Maple Mono NF.

## Layout

```
bootstrap.sh         first boot, and what `mico bootstrap` runs
scripts/mico         the command
flake.nix            nixpkgs + home-manager
home/                zsh, git, tools, packages
hosts/               arch.nix, wsl.nix
packages/            pacman and AUR lists
config/              zellij, kitty, bat, podman
.config/nvim         neovim
```
