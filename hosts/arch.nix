{
  config,
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
  # Syncthing - laptop <-> phone <-> Windows desktop.
  #
  # Deliberately laptop-only. WSL is excluded because syncing into a VHDX that
  # spends most of its life powered off achieves nothing, and the Windows host is
  # the right place to run Syncthing for that machine.
  #
  # This is the one service nix owns. It is a per-user data daemon running as a
  # systemd --user unit, not a system service, so it stays on the nix side of the
  # split rule - but it IS an exception worth knowing about.
  #
  # Pairing is declarative, not click-through: put a device's ID in `devices` and
  # activate. Do NOT accept devices or folders in the web UI - overrideDevices and
  # overrideFolders both default to true, so anything added by hand is deleted on
  # the next `hms`.
  #
  # This machine's own device ID does not need declaring. Verified against a live
  # instance: submitting a folder that lists only the phone came back normalised
  # to [phone, local], because Syncthing inserts the local device itself.
  #
  # Windows is configured manually in its Syncthing app; this Nix block only
  # declares what the Arch laptop shares with it.
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

        # This laptop has 7G of RAM with roughly 2G available and swap already in
        # use, and Syncthing holds its index in memory. Scanning one folder at a
        # time trades a little speed for a lower peak.
        maxFolderConcurrency = 1;
      };

      # Device IDs are public keys, so committing them is fine.
      devices = {
        phone.id = "3A5SBCS-TY35O3C-NZS6Q2S-RHUP5IV-KIAAQ5E-HOVWHZT-NMUHPDV-D3FY7Q5";
        desktop.id = "MZMZAS4-VKZ3IBN-2OKTMZM-2ROYXPW-BU53VSU-FNNSOJM-YIPCG6Q-FUCPLQ3";
      };

      folders = {
        # Bidirectional so laptop <-> desktop changes relay through the phone,
        # and vice versa.
        #
        # trashcan versioning is a 30-day undo window, not an archive: Syncthing
        # only versions files it removes on your behalf, so a deletion you make
        # locally is still a deletion. It does protect against the *other* device
        # deleting something you wanted.
        documents = {
          id = "documents";
          path = "${config.home.homeDirectory}/Documents";
          devices = [
            "phone"
            "desktop"
          ];
          type = "sendreceive";
          versioning = {
            type = "trashcan";
            params.cleanoutDays = "30";
          };
        };

        # Syncthing creates a missing folder path and its .stfolder marker itself,
        # verified against a live instance, so ~/Sync needs no activation step.
        shared = {
          id = "shared";
          path = "${config.home.homeDirectory}/Sync";
          devices = [
            "phone"
            "desktop"
          ];
          type = "sendreceive";
          versioning = {
            type = "trashcan";
            params.cleanoutDays = "30";
          };
        };
      };
    };
  };
}
