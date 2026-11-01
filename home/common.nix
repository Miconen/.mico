{
  pkgs,
  lib,
  config,
  username,
  hostName,
  repoPath,
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
    ./claude.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    # Do not bump casually; controls backwards-compat defaults.
    stateVersion = "26.05";

    # Only packages without a programs.* module; modules install their own.
    packages = with pkgs; [
      # search / inspect
      ripgrep
      fd
      jq
      tree

      # files / archives
      eza
      unzip
      curl
      wget
      less
      dust
      duf

      # media
      ffmpeg

      # system
      fastfetch
      wl-clipboard

      # nvim-treesitter needs the CLI >= 0.26.1, not the npm build.
      tree-sitter

      # git / dev
      gh
      opencode
      claude-code
      cloc
      lazygit
      lazydocker
      git-absorb
      difftastic
      yq-go
      air
      uv

      zellij
      neovim

      (writeShellScriptBin "mico" ''
        export MICO_REPO=${lib.escapeShellArg repoPath}
        export MICO_HOST=${lib.escapeShellArg hostName}
        exec bash "$MICO_REPO/scripts/mico" "$@"
      '')

      # fonts
      maple-mono.NF
      noto-fonts-color-emoji
    ];

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      SUDO_EDITOR = "nvim";

      GOPATH = "${config.home.homeDirectory}/go";

      # mise owns Python versions; stop uv downloading its own.
      UV_PYTHON_PREFERENCE = "only-system";

      # Rootless podman; needs `systemctl --user enable --now podman.socket`.
      DOCKER_HOST = "unix://$XDG_RUNTIME_DIR/podman/podman.sock";
    };

    sessionPath = [
      "${config.home.homeDirectory}/.local/bin"
      "${config.home.homeDirectory}/go/bin"
    ];
  };

  fonts.fontconfig.enable = true;

  programs.home-manager.enable = true;

  programs.nh = {
    enable = true;
    homeFlake = repoPath;
  };

  # Only covers this user's profiles; bootstrap.sh installs the system-profile timer.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    persistent = true;
    options = "--delete-older-than 30d";
  };

  programs.zsh.shellAliases.hms = "mico switch";

  xdg.enable = true;

  # Out-of-store so lazy.nvim can write lazy-lock.json (commit its changes).
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/.config/nvim";

  # A dangling symlink shows up as "no config" rather than an error.
  home.activation.checkNvimConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    nvimSrc="${repoPath}/.config/nvim"
    if [ ! -f "$nvimSrc/init.lua" ]; then
      warnEcho "nvim config missing at $nvimSrc - is the repo checkout complete?"
    fi
  '';
}
