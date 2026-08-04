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
  # zellij's config is ~150 lines of nested KDL keybindings and tmux.conf is
  # terse imperative directives. Translating either into Nix attribute sets
  # would be unreadable and risk silent breakage for zero functional gain, so
  # they are managed as files. They are still fully version-controlled and
  # still reproduce identically on every machine.
  # ---------------------------------------------------------------------------
  xdg.configFile = {
    "zellij/config.kdl".source = ../config/zellij/config.kdl;
    "zellij/layouts/default.kdl".source = ../config/zellij/layouts/default.kdl;
    "tmux/tmux.conf".source = ../config/tmux/tmux.conf;
  };
}
