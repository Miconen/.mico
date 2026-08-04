{
  ...
}:
{
  # ---------------------------------------------------------------------------
  # Arch laptop (Hyprland + Plasma bits, sddm, pipewire - all pacman-managed).
  #
  # Nothing GUI belongs here. Per the split rule, pacman owns the kernel,
  # drivers, display manager, desktop, compositor, build toolchain (gcc,
  # base-devel), the zsh binary itself, the recovery editors (vim, nano),
  # openssh, podman and paru. This file is only for CLI tooling that the WSL
  # host should NOT get.
  # ---------------------------------------------------------------------------

  programs.zsh.shellAliases.hms = "home-manager switch --flake ~/.mico#arch";

  # keychain handles ssh-agent here. It is enabled by default in home/tools.nix;
  # hosts/wsl.nix turns it off in favour of wsl2-ssh-agent.
}
