{
  pkgs,
  lib,
  ...
}:
let
  # Windows binaries by absolute path, not bare name. With
  # `appendWindowsPath=false` in /etc/wsl.conf - which the README recommends, to
  # stop Windows PATH entries shadowing nix binaries - `clip.exe` and
  # `powershell.exe` are NOT on PATH.
  clipExe = "/mnt/c/Windows/System32/clip.exe";
  psExe = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";

  # Prefer WSLg's Wayland clipboard (Windows 11, shares the Windows clipboard),
  # fall back to Windows interop so this also works on WSL1 / Windows 10 / WSLg
  # disabled.
  pbcopy = pkgs.writeShellScriptBin "pbcopy" ''
    if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -x ${pkgs.wl-clipboard}/bin/wl-copy ]; then
      exec ${pkgs.wl-clipboard}/bin/wl-copy "$@"
    fi
    exec ${clipExe}
  '';

  pbpaste = pkgs.writeShellScriptBin "pbpaste" ''
    if [ -n "''${WAYLAND_DISPLAY:-}" ] && [ -x ${pkgs.wl-clipboard}/bin/wl-paste ]; then
      exec ${pkgs.wl-clipboard}/bin/wl-paste --no-newline
    fi
    # PowerShell emits CRLF; strip the CR or every paste gains ^M.
    ${psExe} -NoProfile -NoLogo -Command Get-Clipboard | tr -d '\r'
  '';
in
{
  # ---------------------------------------------------------------------------
  # WSL host. UNTESTED - written from the WSL package manifest that used to live
  # at packages/packages.txt (paru, podman, podman-compose, wsl2-ssh-agent,
  # vulkan-dzn, postgresql) plus the WSL branches of the old .zshrc.
  #
  # Prerequisites on the Windows side, in /etc/wsl.conf:
  #
  #   [boot]
  #   systemd=true          # REQUIRED, the multi-user nix daemon needs it
  #
  #   [interop]
  #   appendWindowsPath=false   # optional, see README tradeoff
  #
  # Then `wsl --shutdown` before installing nix.
  # ---------------------------------------------------------------------------

  programs.zsh.shellAliases.hms = "home-manager switch --flake ~/.mico#wsl";

  # WSL uses wsl2-ssh-agent to bridge to the Windows ssh-agent, so keychain
  # would fight it for SSH_AUTH_SOCK.
  programs.keychain.enable = false;

  # Windows Git Credential Manager. Only valid inside WSL; on the laptop this
  # path does not exist, which is why the old unconditional .gitconfig entry
  # was broken there.
  programs.git.settings.credential.helper =
    "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe";

  # Clipboard. wl-clipboard gives wl-copy/wl-paste, which neovim autodetects
  # when WAYLAND_DISPLAY is set under WSLg - no g:clipboard config needed.
  # pbcopy/pbpaste are the portable entry points that work either way.
  home.packages = [
    pkgs.wl-clipboard
    pbcopy
    pbpaste
  ];

  programs.zsh.initContent = lib.mkMerge [
    (lib.mkOrder 550 ''
      # Bridge to the Windows ssh-agent. Installed via pacman (AUR), not nix,
      # because it is a system integration binary living in /usr/sbin.
      if [[ -o interactive && -x /usr/sbin/wsl2-ssh-agent ]]; then
        eval "$(/usr/sbin/wsl2-ssh-agent)"
      fi
    '')

    (lib.mkOrder 1000 ''
      # Familiar aliases for the clipboard wrappers above.
      alias clip='pbcopy'
      alias paste='pbpaste'
    '')
  ];
}
