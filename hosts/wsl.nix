{
  lib,
  ...
}:
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
  programs.git.extraConfig.credential.helper =
    "/mnt/c/Program Files/Git/mingw64/bin/git-credential-manager.exe";

  programs.zsh.initContent = lib.mkOrder 550 ''
    # Bridge to the Windows ssh-agent. Installed via pacman (AUR), not nix,
    # because it is a system integration binary living in /usr/sbin.
    if [[ -o interactive && -x /usr/sbin/wsl2-ssh-agent ]]; then
      eval "$(/usr/sbin/wsl2-ssh-agent)"
    fi
  '';
}
