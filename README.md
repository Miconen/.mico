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

## Adding a package

Try it first without installing anything - `comma` runs it straight from nixpkgs:

```bash
, cowsay hello              # one-off, nothing persisted
nsearch ripgrep             # nix search nixpkgs ripgrep
nwhich bin/ffmpeg           # nix-locate: which package provides this binary
```

If you want to keep it, add one line to `home.packages`:

```bash
pkgconf                     # opens home/common.nix
hms
```

That is the whole workflow. Two rules:

- **Never `nix profile install`.** It is invisible to this repo and drifts between
  machines. `comma` and `nix shell nixpkgs#foo` cover the throwaway case.
- **If a tool has a `programs.*` module, prefer it** over `home.packages`. The
  module manages config too, which is the difference between btop keeping its
  settings across machines and btop writing its own file on first run. Check with
  `man home-configuration.nix` or search the home-manager options site.

Adding a **new file** under `home/` also needs `git add`, because flakes ignore
untracked files - nix will tell you so by name if you forget.

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
./ci/lint.sh          # nixfmt, statix, deadnix, shellcheck, shfmt, actionlint, zellij
./ci/zellij-check.sh  # starts a real session and asserts on the live layout
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
Ctrl-g   lock / unlock (pass keys straight through to the terminal)
Ctrl-p   pane      Ctrl-t   tab       Ctrl-n   resize
Ctrl-s   scroll    Ctrl-m   move      (in tab mode: , / . break pane left/right)
Alt-d    detach            Ctrl-q   quit (DESTROYS the session)
Alt-, / Alt-.     cycle swap layouts   (Alt-[ / Alt-] also work)
Alt-h/j/k/l       move focus        Alt-n   new pane
```

Bindings avoid `[` and `]` as primaries: on a Finnish ISO keyboard those are
AltGr+8 / AltGr+9, so `Alt-[` is effectively unreachable. `,` and `.` are
unshifted and adjacent. The bracket forms are kept as secondary bindings.

**Config changes need the session recreated.** zellij reads its config only when
the session's server starts, there is no reload action, and
`session_serialization` makes `attach` resurrect the *old* layout - so editing
`config.kdl` and running `hms` appears to do nothing:

```bash
zreload            # zellij delete-session --force main
```

That ends the current session (the terminal closes, since `.zshrc` exec'd into
it). Open a new terminal for a fresh session on the new config. `hms` alone only
re-execs zsh *inside* the existing session.

**Tab names follow the project automatically.** A `chpwd` hook renames the tab to
the git repo name, or the directory name outside a repo, or `~` at home. No
keybind and nothing to run. It skips the subprocess when the name has not changed.

**New tabs get the status bar via `default_tab_template`.** A named
`tab_template` only applies to tabs written into the layout file; tabs created at
runtime use zellij's `new_tab_template`, which only `default_tab_template`
populates. `zellij action dump-layout` on a live session showed
`new_tab_template { }` - empty - which is why new tabs had no bar.

**`on_force_close "detach"`.** This fires when the terminal holding the session is
closed. It used to be `"quit"`, which destroyed the session on every window close
and made `session_serialization` pointless. With `detach`, closing kitty leaves
panes and cwds intact for next time. `detach` is also zellij's own default.

**There is deliberately no session mode.** Six binds for things you can reach from
the CLI when you actually need them:

```bash
zellij action launch-or-focus-plugin zellij:session-manager --floating
zellij ls                    # list sessions
zellij kill-session main     # if a session gets wedged
```

`ZELLIJ_SKIP=1` starts a shell without attaching, for when a multiplexer is in the
way.

## Syncthing

Laptop only. WSL is excluded on purpose: syncing into a VHDX that is usually
powered off achieves nothing, and Windows is the right place to run Syncthing for
that machine.

This is the one service nix owns. It is a per-user data daemon on a
`systemd --user` unit rather than a system service, so it sits on the nix side of
the split rule - but it is an exception worth knowing about.

**Pairing is declarative, not click-through.** Put a device ID in
`services.syncthing.settings.devices` and activate. Do **not** accept devices or
folders in the web UI: `overrideDevices` and `overrideFolders` both default to
true, so anything added by hand is deleted on the next `hms`. Device IDs are
public keys, so committing them is fine.

GUI is `127.0.0.1:8384`, localhost only, so no password is needed - which also
means no secret ever has to live in this public repo.

### Status: Phase 2 done

| phase | what |
| --- | --- |
| 1 done | service only |
| 2 done | phone paired; `documents` -> `~/Documents`, `shared` -> `~/Sync`, both bidirectional with 30-day trashcan |
| 3 | add the desktop; `phone-camera`, bidirectional with trashcan |

**This machine's own device ID does not need declaring.** Verified against a live
instance: a folder submitted listing only the phone came back normalised to
`[phone, local]`, because Syncthing inserts the local device itself.

`~/Sync` is created by Syncthing along with its `.stfolder` marker, also verified,
so there is no activation step for it.

### Pairing a phone or the desktop

Get this laptop's ID **on the laptop**:

```bash
syncthing device-id
```

`http://127.0.0.1:8384` is the laptop's own web UI, opened in a browser on the
laptop - not something you type into the phone. **Actions -> Show ID** there also
shows a QR code, which beats typing 63 characters into a phone.

Then in Syncthing-Fork, **Add Device**:

| field | value | why |
| --- | --- | --- |
| ID | the laptop's device ID | or scan the QR |
| Name | anything, e.g. `2B` | a local label only, never synced |
| Addresses | leave `dynamic` | auto-discovery plus relay fallback. Hard-coding an address breaks when the LAN IP changes, and this laptop is behind port-restricted NAT anyway |
| Folders | leave empty | the laptop already offers `documents` and `shared`; accept the prompt instead |
| Introducer | **off** | it would let the laptop auto-add other devices to the phone, but `overrideDevices = true` means the laptop deletes anything auto-added, so pairing stays explicit |
| Auto accept | **off** | otherwise folders are created at a path Syncthing picks for you |
| Pause device | off | |
| Untrusted device | **off** | that is the encrypted-relay mode, which was dropped; it needs a folder password and forces `receiveencrypted` |

Accept the two folder shares on the phone when they appear. Do **not** accept
anything on the laptop side - `overrideFolders` reverts it.

`bootstrap.sh` reports on the service but deliberately does not
`systemctl enable` it, since home-manager owns the unit.

### Things that will bite you

- **Syncthing has no store-and-forward.** Two devices exchange data only while
  both are online. The public relay servers only help with NAT traversal; they do
  not hold your files. Laptop and desktop are never on together, so the phone is a
  member of the shared folders purely so changes can travel through it.
- **The official Android app was archived in Dec 2024.** Use
  [Syncthing-Fork](https://github.com/Catfriend1/syncthing-android), and exempt it
  from battery optimisation or Doze will stall relaying.
- **Folder IDs must match across devices.** The ID pairs a folder, not the label
  or the path.
- **It is not a backup.** The camera folder is bidirectional by choice, so a
  deletion propagates. `trashcan` versioning with a 30-day window makes a
  mis-click recoverable from `.stversions`, but Syncthing does not version
  deletions you originate locally. Real photo backup is a separate job.
- **Memory.** Measured at 31M RSS with `documents` + `shared`, so the laptop's 7G
  is a non-issue at this size. `maxFolderConcurrency = 1` is kept as precaution
  for when the camera folder adds thousands of files, not because it is needed
  now. Check with `systemctl --user status syncthing`.
- **This connection is relay-dependent for remote peers.** The laptop logged
  `Detected NAT type: Port restricted NAT` and `Detected NAT services (count=0)`,
  meaning no UPnP/NAT-PMP port mapping is available, so it joined a public relay.
  On the same LAN, local discovery gives direct transfers and this does not
  matter. Phone-to-desktop over the internet will go through a relay, which is
  fine for documents but slow for a photo library - forward TCP+UDP 22000 on the
  router if that becomes annoying.
- RuneLite is deliberately **not** synced here; its own profile sync handles it,
  which also keeps `credentials.properties` off the phone.

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

**`--check` reports a `*-debug` package.** A makepkg by-product: Arch defaults to
`OPTIONS=(debug)`, and `makepkg -si` installs every artifact it built. bootstrap
now builds and installs separately so only non-debug packages land, but an
already-installed one has to go by hand:

```bash
sudo pacman -Rns paru-bin-debug
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
- **btop cannot save settings changed inside the app.** `btop.conf` is generated
  from `programs.btop.settings`, so it is a read-only store symlink and btop's
  write-on-exit fails. Same trade-off as `~/.zshrc`: change it in `home/tools.nix`
  and run `hms`. Note btop normalises `True` to `true` when it *can* write, which
  is why the generated capitalisation is harmless - verified that btop keeps our
  values rather than reverting to its defaults.
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
