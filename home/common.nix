{
  pkgs,
  config,
  username,
  ...
}:
{
  imports = [
    ./zsh.nix
    ./starship.nix
    ./git.nix
    ./fzf.nix
    ./mise.nix
    ./tools.nix
    ./nix-gc.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    # Do not bump this casually; it controls backwards-compat defaults.
    stateVersion = "26.05";

    # Packages that have no dedicated programs.* module.
    # Anything with a module (fzf, bat, zoxide, direnv, starship, mise,
    # keychain, git/delta) is installed by that module instead - do not
    # duplicate it here.
    packages = with pkgs; [
      # search / inspect
      ripgrep
      fd
      jq
      tree

      # listing - eza is a plain package on purpose, see tools.nix
      eza

      # files / archives
      unzip
      curl
      wget
      less
      dust
      duf

      # system
      htop
      fastfetch

      # git / dev
      gh
      lazygit
      lazydocker

      # terminal multiplexers (configs are managed verbatim, see tools.nix)
      zellij
      tmux

      # editor (config stays in the nvim submodule, see below)
      neovim

      # terminal font, needed for starship's Catppuccin Powerline glyphs
      maple-mono.NF
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      SUDO_EDITOR = "nvim";

      GOPATH = "${config.home.homeDirectory}/go";

      # Rootless podman socket. Requires:
      #   systemctl --user enable --now podman.socket
      # $XDG_RUNTIME_DIR is intentionally left unexpanded so it resolves at
      # shell startup rather than at build time.
      DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
    };

    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/go/bin"
    ];
  };

  # Makes nix-installed fonts visible to kitty and the rest of the system
  # via ~/.local/share/fonts. Fonts are the one exception to the
  # "nix is CLI-only" rule, because the prompt depends on one.
  fonts.fontconfig.enable = true;

  # Self-hosting: guarantees the `home-manager` CLI matches this flake.
  programs.home-manager.enable = true;

  xdg.enable = true;

  # Neovim config is still its own repo (Miconen/nvim), tracked as a submodule
  # at .config/nvim. mkOutOfStoreSymlink points at the working tree rather than
  # the nix store, so lazy.nvim and Mason can still write lazy-lock.json etc.
  # Requires: git -C ~/.mico submodule update --init --recursive
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.mico/.config/nvim";
}
