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

  # keychain handles ssh-agent here. It is enabled by default in home/tools.nix;
  # hosts/wsl.nix turns it off in favour of wsl2-ssh-agent.
  # The hms alias is built from hostName in home/common.nix.

  # kitty's binary comes from pacman (GUI), but its config is managed here so
  # the Nerd Font and Catppuccin theme are not a manual post-install step.
  # WSL does not get this - it uses Windows Terminal.
  xdg.configFile."kitty/kitty.conf".source = ../config/kitty/kitty.conf;

  # ---------------------------------------------------------------------------
  # Syncthing - PHASE 1: service only, no devices and no folders yet.
  #
  # Deliberately laptop-only. WSL is excluded because syncing into a VHDX that
  # spends most of its life powered off achieves nothing, and the Windows host is
  # the right place to run Syncthing for that machine.
  #
  # This is also the one service nix owns. It is a per-user data daemon running as
  # a systemd --user unit, not a system service, so it stays on the nix side of
  # the split rule - but it IS an exception worth knowing about.
  #
  # Pairing is declarative, not click-through: put a device's ID in `devices`
  # below and activate. Do NOT accept devices or folders in the web UI -
  # overrideDevices and overrideFolders both default to true, so anything added by
  # hand is deleted on the next `hms`.
  #
  # Next step: read this machine's ID from http://127.0.0.1:8384 (Actions ->
  # Show ID) and add it, plus the phone's, under `devices`.
  # ---------------------------------------------------------------------------
  services.syncthing = {
    enable = true;

    # Explicit even though both already default to true, because the behaviour is
    # load-bearing: the flake is the only source of truth.
    overrideDevices = true;
    overrideFolders = true;

    # Localhost only, so no GUI password is needed - which also means no secret
    # would ever have to live in this public repo.
    guiAddress = "127.0.0.1:8384";

    settings = {
      options = {
        # -1 is "declined", which also stops Syncthing prompting about it.
        urAccepted = -1;
      };

      # Phase 2 adds the phone here, Phase 3 the desktop. Device IDs are public
      # keys, so committing them is fine.
      devices = { };

      # Phase 2: documents -> ~/Documents, shared -> ~/Sync.
      # Phase 3: phone-camera, bidirectional with trashcan versioning.
      folders = { };
    };
  };
}
