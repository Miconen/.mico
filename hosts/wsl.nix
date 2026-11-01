{
  pkgs,
  lib,
  ...
}:
let
  # Absolute paths: with appendWindowsPath=false these aren't on PATH.
  clipExe = "/mnt/c/Windows/System32/clip.exe";
  psExe = "/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
  explorerExe = "/mnt/c/Windows/explorer.exe";
  winChromeExe = "/mnt/c/Program Files/Google/Chrome/Application/chrome.exe";

  # Prefer WSLg's Wayland clipboard, fall back to Windows interop.
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
    # PowerShell emits CRLF.
    ${psExe} -NoProfile -NoLogo -Command Get-Clipboard | tr -d '\r'
  '';

  # Hands URLs and paths to Windows (replaces wslu's wslview).
  xdgOpen = pkgs.writeShellScriptBin "xdg-open" ''
    set -euo pipefail
    target="$1"
    case "$target" in
      http://*|https://*|mailto:*) ;;
      *) target="$(wslpath -w -- "$target")" ;;
    esac
    # explorer.exe exits 1 on success.
    ${explorerExe} "$target" || true
    exit 0
  '';

  # Windows Chrome with CDP for Playwright's connectOverCDP(). A separate
  # profile is required or Chrome ignores --remote-debugging-port.
  winChromeDebug = pkgs.writeShellScriptBin "win-chrome-debug" ''
    set -euo pipefail
    mkdir -p "$HOME/.cache/win-chrome-debug-profile"
    profile="$(wslpath -w "$HOME/.cache/win-chrome-debug-profile")"
    exec "${winChromeExe}" \
      --remote-debugging-port=9222 \
      --user-data-dir="$profile" \
      "$@"
  '';
in
{
  # WSL host. Needs `[boot] systemd=true` in /etc/wsl.conf (see README).

  # wsl2-ssh-agent bridges to the Windows agent; keychain would fight it.
  programs.keychain.enable = false;

  programs.git.settings.credential.helper =
    "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe";

  home.packages = [
    pbcopy
    pbpaste
    xdgOpen
    winChromeDebug
  ];

  home.sessionVariables.BROWSER = "xdg-open";

  programs.zsh.initContent = lib.mkMerge [
    (lib.mkOrder 550 ''
      # wsl2-ssh-agent comes from the AUR, not nix.
      if [[ -o interactive && -x /usr/sbin/wsl2-ssh-agent ]]; then
        eval "$(/usr/sbin/wsl2-ssh-agent)"
      fi
    '')

    (lib.mkOrder 900 ''
      # Chrome's CDP port is reached via a Windows portproxy on the WSL gateway (see README).
      if [[ -o interactive ]]; then
        export PW_CDP_URL="http://$(ip route show default | awk '{print $3; exit}'):9223"
      fi
    '')

    (lib.mkOrder 1000 ''
      alias clip='pbcopy'
      alias paste='pbpaste'
    '')
  ];
}
