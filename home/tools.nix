{
  lib,
  config,
  ...
}:
{
  # NOTE: programs.eza is deliberately NOT enabled. Its zsh integration defines
  # shellAliases.ls = "eza", which collides with the richer `ls` alias in
  # zsh.nix and makes evaluation fail with a conflicting-definition error.
  # eza is installed as a plain package in common.nix instead.

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

  # Shell history: better search, stats, and dedup than raw zsh history.
  #
  # Local-only for now. Cross-machine sync is atuin's own encrypted protocol -
  # do NOT try to sync ~/.local/share/atuin with Syncthing or similar, it is a
  # live SQLite database and file-syncing it corrupts it.
  #
  # Key bindings are split deliberately:
  #   Ctrl-R      atuin  (home/fzf.nix yields it by blanking fzf's historyWidget)
  #   Up / Down   zsh-history-substring-search, via --disable-up-arrow
  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    flags = [ "--disable-up-arrow" ];
    settings = {
      # Search the shell history of this machine only, newest first.
      filter_mode = "global";
      style = "compact";
      inline_height = 15;
      show_preview = true;
      # Skip commands that are noise in history search.
      history_filter = [
        "^ "
        "^clear$"
        "^c$"
        "^exit$"
        "^:q$"
      ];
    };
  };

  # nix-index gives `nix-locate bin/foo` (which package provides this file), and
  # the database flake input makes `,` (comma) work: `, cowsay hi` runs a package
  # without installing it. Both exist so that "never install imperatively" stays
  # convenient rather than annoying.
  programs.nix-index.enable = true;
  programs.nix-index-database.comma.enable = true;

  # btop replaces htop. Managed through the module rather than as a bare package
  # so btop.conf is generated instead of btop writing its own on first run - which
  # would then drift silently and never reproduce on another machine.
  programs.btop = {
    enable = true;

    # `themes` takes a path, so the file is vendored like the bat theme and the
    # zellij config rather than being inlined into Nix.
    themes.catppuccin_mocha = ../config/btop/catppuccin_mocha.theme;

    settings = {
      # Matches the theme filename above, without the .theme suffix.
      color_theme = "catppuccin_mocha";

      # Let kitty's background show through instead of btop painting its own.
      # Both are Catppuccin #1e1e2e, so this only matters if kitty ever gets
      # transparency.
      theme_background = false;

      # hjkl and gg/G, consistent with neovim, zellij and tmux's mode-keys vi.
      vim_keys = true;

      # update_ms is left at btop's default of 2000. This is a Carrizo-era APU, so
      # a faster refresh costs more than it is worth.
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    # Caches nix devshell evaluation so `cd`-ing into a project isn't slow.
    nix-direnv.enable = true;
  };

  programs.keychain = {
    # mkDefault so hosts/wsl.nix can set this to false. Without it, `true` here
    # and `false` there are two conflicting definitions of a types.bool option,
    # which is a hard evaluation error rather than an override.
    enable = lib.mkDefault true;
    enableZshIntegration = true;
    keys = [ "id_ed25519" ];
    # `agents` is deprecated as of keychain 2.9.0, which detects the agent type
    # itself. Setting it only produces a warning now.
  };

  # ---------------------------------------------------------------------------
  # Verbatim configs.
  #
  # zellij's config is ~170 lines of nested KDL keybindings, and kitty.conf is
  # plain key/value. Translating either into Nix attribute sets would be
  # unreadable and risk silent breakage for zero functional gain, so they are
  # managed as files. They are still fully version-controlled and still
  # reproduce identically on every machine.
  # ---------------------------------------------------------------------------
  xdg.configFile = {
    "zellij/config.kdl".source = ../config/zellij/config.kdl;
    "zellij/layouts/default.kdl".source = ../config/zellij/layouts/default.kdl;
    # Rootless podman on btrfs home — see config/containers/storage.conf.
    "containers/storage.conf".source = ../config/containers/storage.conf;
  };

  # storage.conf alone is not enough if a previous run already created an
  # overlay store: podman keeps targeting .../storage/overlay and errors.
  # Drop that incompatible store once so the btrfs driver can initialize.
  home.activation.podmanBtrfsStorage = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    store="${config.home.homeDirectory}/.local/share/containers/storage"
    conf="${config.home.homeDirectory}/.config/containers/storage.conf"
    if [ ! -f "$conf" ] || ! grep -q 'driver = "btrfs"' "$conf"; then
      warnEcho "podman storage.conf missing btrfs driver at $conf (hms incomplete?)"
    fi
    if [ -d "$store/overlay" ] || [ -d "$store/overlay-images" ] || [ -d "$store/overlay-layers" ]; then
      noteEcho "removing leftover podman overlay store (incompatible with btrfs driver)"
      # Stop rootless API so it does not hold files open.
      if command -v systemctl >/dev/null; then
        $DRY_RUN_CMD systemctl --user stop podman.socket podman.service 2>/dev/null || true
      fi
      $DRY_RUN_CMD rm -rf "$store"
      if command -v systemctl >/dev/null; then
        $DRY_RUN_CMD systemctl --user start podman.socket 2>/dev/null || true
      fi
    fi
  '';
}
