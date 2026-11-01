{
  lib,
  repoPath,
  ...
}:
{
  # programs.eza is NOT enabled: its `ls` alias conflicts with the one in zsh.nix.

  programs.bat = {
    enable = true;

    config = {
      theme = "Catppuccin Mocha";
      style = "numbers,changes,header";
    };

    themes = {
      "Catppuccin Mocha" = {
        src = ../config/bat/themes;
        file = "Catppuccin Mocha.tmTheme";
      };
    };
  };

  # Ctrl-R is atuin; Up/Down stay with zsh-history-substring-search.
  # Never file-sync ~/.local/share/atuin: it's a live SQLite db.
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      filter_mode = "global";
      style = "compact";
      inline_height = 15;
      show_preview = true;
      history_filter = [
        "^ "
        "^clear$"
        "^c$"
        "^exit$"
        "^:q$"
      ];
    };
  };

  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;

  programs.btop = {
    enable = true;

    themes.catppuccin_mocha = ../config/btop/catppuccin_mocha.theme;

    settings = {
      color_theme = "catppuccin_mocha";
      theme_background = false;
      vim_keys = true;
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.keychain = {
    # mkDefault so hosts/wsl.nix can disable it without a conflicting definition.
    enable = lib.mkDefault true;
    enableZshIntegration = true;
    keys = [ "id_ed25519" ];
  };

  xdg.configFile = {
    "zellij/config.kdl".source = ../config/zellij/config.kdl;
    "zellij/layouts/default.kdl".source = ../config/zellij/layouts/default.kdl;
    "containers/registries.conf".source = ../config/containers/registries.conf;
    # Disables netavark's nftables ruleset generation, which breaks on WSL2 kernels.
    "containers/containers.conf".source = ../config/containers/containers.conf;
  };

  # storage.conf isn't a static file: the right graph driver depends on the
  # filesystem (btrfs on the laptop, ext4 on WSL), so a script picks it.
  home.activation.podmanStorage = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    script="${repoPath}/scripts/podman-storage.sh"
    if [ ! -x "$script" ]; then
      verboseEcho "podman storage script missing at $script - skipping"
    elif ! command -v podman >/dev/null; then
      verboseEcho "podman not installed - skipping storage setup"
    else
      $DRY_RUN_CMD "$script" --quiet || \
        warnEcho "podman storage setup failed - run $script by hand"
    fi
  '';
}
