{
  config,
  ...
}:
{
  # Arch laptop. pacman owns everything GUI/system; this file is CLI config the
  # WSL host shouldn't get.

  xdg.configFile."kitty/kitty.conf".source = ../config/kitty/kitty.conf;

  # Syncthing: laptop <-> phone <-> Windows desktop.
  # Pairing is declarative: anything accepted in the web UI is deleted on the
  # next switch. The local device needn't be listed; Syncthing adds it itself.
  services.syncthing = {
    enable = true;

    overrideDevices = true;
    overrideFolders = true;

    # Localhost only, so no GUI password (no secret in this public repo).
    guiAddress = "127.0.0.1:8384";

    settings = {
      options = {
        urAccepted = -1;
        # Low-RAM laptop; scan one folder at a time to cap peak memory.
        maxFolderConcurrency = 1;
      };

      # Device IDs are public keys.
      devices = {
        phone.id = "3A5SBCS-TY35O3C-NZS6Q2S-RHUP5IV-KIAAQ5E-HOVWHZT-NMUHPDV-D3FY7Q5";
        desktop.id = "MZMZAS4-VKZ3IBN-2OKTMZM-2ROYXPW-BU53VSU-FNNSOJM-YIPCG6Q-FUCPLQ3";
      };

      # trashcan versioning only protects against deletions made by OTHER devices.
      folders = {
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
