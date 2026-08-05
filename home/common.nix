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
      # btop is installed by programs.btop in tools.nix, not listed here.
      fastfetch

      # Wayland clipboard. Needed for neovim's "+y on Hyprland and for anything
      # that shells out to a clipboard helper. The laptop previously had no
      # clipboard tool at all - wl-clipboard was only declared for WSL.
      wl-clipboard

      # git / dev
      gh
      lazygit
      lazydocker
      # Routes staged changes into the right commit of a stack automatically.
      git-absorb
      # Structural (syntax-aware) diffs. Exposed as the `dft` alias rather than
      # replacing delta, which stays the pager for review.
      difftastic
      # jq covers JSON; this is the YAML/TOML equivalent. Provides `yq`.
      yq-go

      # terminal multiplexer (config is managed verbatim, see tools.nix)
      zellij

      # editor (config stays in the nvim submodule, see below)
      neovim

      # terminal font, needed for starship's Catppuccin Powerline glyphs
      maple-mono.NF

      # Maple Mono NF has no emoji coverage, so without this emoji render as
      # tofu. NOTE: the attribute is noto-fonts-color-emoji; noto-fonts-emoji
      # no longer exists.
      noto-fonts-color-emoji
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

  # nh wraps home-manager and prints a package diff of what an activation
  # actually changed. NH_HOME_FLAKE means `nh home switch` needs no path.
  programs.nh = {
    enable = true;
    homeFlake = repoPath;
  };

  # Weekly garbage collection of THIS user's profile.
  #
  # This replaces a hand-written systemd.user timer that used to live in
  # home/nix-gc.nix. The options are `nix.gc.*` but they are declared in
  # modules/services/nix-gc.nix upstream, which is why searching for a
  # modules/misc/nix.nix earlier turned up nothing and led to the wrong
  # conclusion that no such option existed.
  #
  # Upstream is explicit that this only covers the current user's profiles, so
  # the root/system profile timer installed by bootstrap.sh is still required.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    persistent = true;
    options = "--delete-older-than 30d";
  };

  # Built from hostName rather than duplicated in each hosts/*.nix.
  #
  # `zsh -n` is a parse-only syntax check. A successful activation does NOT imply
  # a valid .zshrc - home-manager never parses the zsh it writes - so without
  # this guard a typo in zsh.nix would exec you straight into a broken shell and
  # take away the shell you needed to fix it.
  programs.zsh.shellAliases.hms = "nh home switch ${repoPath} -c ${hostName} -b backup && zsh -n ~/.zshrc && exec zsh";

  xdg.enable = true;

  # Neovim config is still its own repo (Miconen/nvim), tracked as a submodule
  # at .config/nvim. mkOutOfStoreSymlink points at the working tree rather than
  # the nix store, so lazy.nvim and Mason can still write lazy-lock.json etc.
  # Requires: git -C ${repoPath} submodule update --init --recursive
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink "${repoPath}/.config/nvim";

  # The symlink above happily points at an empty directory if the submodule was
  # never initialised, which shows up as "neovim has no config" rather than as
  # an error. Warn loudly instead.
  home.activation.checkNvimSubmodule = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    nvimSrc="${repoPath}/.config/nvim"
    if [ -z "$(ls -A "$nvimSrc" 2>/dev/null)" ]; then
      warnEcho "nvim submodule is empty. Run: git -C ${repoPath} submodule update --init --recursive"
    fi
  '';
}
