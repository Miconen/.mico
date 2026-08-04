{
  lib,
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
  };
}
