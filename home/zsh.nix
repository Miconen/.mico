{
  lib,
  config,
  ...
}:
{
  programs.zsh = {
    enable = true;

    # Keep ~/.zshrc at the conventional location. Left explicit because the
    # default flips to $XDG_CONFIG_HOME/zsh at stateVersion 26.05, which would
    # silently relocate the config and require ZDOTDIR indirection.
    dotDir = config.home.homeDirectory;

    enableCompletion = true;
    autocd = false;

    # NOTE: syntaxHighlighting, autosuggestion and plugins are deliberately NOT
    # used here. The four plugins are tracked as git submodules under
    # .config/zsh/ and sourced from the working tree in initContent below.
    #
    # Submodule SHAs pin them exactly, the same way flake.lock pins nixpkgs, so
    # this is reproducible - but it is a SECOND update mechanism:
    #
    #   nix flake update                  bumps nixpkgs + home-manager
    #   git submodule update --remote     bumps these four plugins
    #
    # To move them back under home-manager, delete the submodules and restore:
    #   syntaxHighlighting.enable = true;
    #   autosuggestion = { enable = true; strategy = [ "history" "completion" ]; };
    #   plugins = [ { name = ...; src = pkgs.zsh-...; file = ...; } ];

    history = {
      # Was 1000 in the old config, which is very small.
      size = 50000;
      save = 50000;
      path = "${config.home.homeDirectory}/.zsh_history";
      append = true;
      extended = true;
      expireDuplicatesFirst = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };

    shellAliases = {
      # File system
      # eza documents `--icons=WHEN`, with an equals sign. Space-separated
      # (`--icons always`) parses `always` as a positional path argument, so
      # `ls` tries to list a file called "always" instead.
      #
      # `always` also emits icons when piped, e.g. `ls | grep foo`. Use
      # `--icons=auto` if you'd rather they only appear on a real terminal.
      ls = "eza -lh --group-directories-first --icons=always";
      lsa = "ls -a";
      lt = "eza --tree --level=2 --long --icons=always --git";
      lta = "lt -a";
      # was: batcat (Debian-only binary name, broken on Arch)
      ff = "fzf --preview 'bat --style=numbers --color=always {}'";
      cd = "z";

      # Configs
      # The old `.zshrc` alias is pointless now: ~/.zshrc is a read-only
      # symlink into the nix store. Edit the source of truth instead.
      zshconf = "nvim ~/.mico/home/zsh.nix";
      nixconf = "nvim ~/.mico/flake.nix";
      ".vimrc" = "nvim ~/.config/nvim";
      nvimdiff = "nvim -d";
      todo = "nvim ~/.todo.md";

      # Directories
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Utility
      ":q" = "exit";
      c = "clear";

      # Tools
      n = "nvim";
      g = "git";
      d = "docker";
      r = "rails";
      lzg = "lazygit";
      lzd = "lazydocker";

      # Containers (podman on both hosts; see DOCKER_HOST in common.nix)
      docker = "podman";
      dcb = "docker compose up --build";
      api = "docker compose --profile dev up --build";

      # Node
      bot = "npm run start | pino-pretty -c";
      bot-test = "AUTH_KEY=123 LOG_LEVEL=silent npm run test";

      # Git
      gcm = "git commit -m";
      gcam = "git commit -a -m";
      gcad = "git commit -a --amend";

      # Zellij
      zf = "zellij action new-pane -f -- ";
    };

    initContent = lib.mkMerge [
      # ---- order 500: earliest ----------------------------------------------
      (lib.mkOrder 500 ''
        # Auto-start zellij.
        #
        # Guards, all of which the previous config lacked:
        #   -o interactive : never hijack `zsh -i -c '...'`
        #   -z $ZELLIJ     : don't nest sessions
        #   -z SSH_CONNECTION : don't hijack remote shells
        #   TERM != dumb   : don't break editors/tooling that spawn a shell
        if [[ -o interactive && -z "$ZELLIJ" && -z "$SSH_CONNECTION" && "$TERM" != "dumb" ]]; then
          if command -v zellij >/dev/null; then
            exec zellij --layout default
          fi
        fi
      '')

      # ---- order 1000: general config ---------------------------------------
      (lib.mkOrder 1000 ''
        # Greeting. Note this runs in every interactive shell, which means every
        # new zellij pane. Comment it out if that gets noisy.
        if [[ -o interactive ]]; then
          fastfetch
        fi

        # Options not covered by programs.zsh.history above
        unsetopt menu_complete
        unsetopt flowcontrol
        setopt prompt_subst
        setopt always_to_end
        setopt auto_menu
        setopt complete_in_word
        setopt hist_verify
        setopt no_list_ambiguous

        # zsh leaves this off by default (unlike bash), which means a pasted
        # command with a trailing `# comment` fails with "command not found: #"
        # or a glob error. On for sanity when copy-pasting.
        setopt interactive_comments

        zstyle ':completion:*' menu select
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      '')

      # ---- order 900: plugins from the git submodules ------------------------
      # Order mirrors what home-manager does for its own plugin handling: after
      # compinit (570), before aliases (1100).
      (lib.mkOrder 900 ''
        ZSH_PLUGIN_DIR="${config.home.homeDirectory}/.mico/.config/zsh"

        ZSH_AUTOSUGGEST_STRATEGY=(history completion)

        for _p in \
          "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" \
          "$ZSH_PLUGIN_DIR/zsh-history-substring-search/zsh-history-substring-search.zsh" \
          "$ZSH_PLUGIN_DIR/zsh-you-should-use/you-should-use.plugin.zsh"; do
          if [[ -f "$_p" ]]; then
            source "$_p"
          else
            print -u2 "zsh: plugin missing: $_p (run: git -C ~/.mico submodule update --init)"
          fi
        done
        unset _p
      '')

      # ---- order 1200: syntax highlighting -----------------------------------
      # Must load after every custom widget has been defined, which is why
      # home-manager's own module also uses 1200 rather than sourcing it with
      # the other plugins.
      # https://github.com/zsh-users/zsh-syntax-highlighting#faq
      (lib.mkOrder 1200 ''
        if [[ -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
          source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        else
          print -u2 "zsh: plugin missing: zsh-syntax-highlighting (run: git -C ~/.mico submodule update --init)"
        fi
      '')

      # ---- last: keybindings ------------------------------------------------
      # Must run after plugin sourcing, otherwise the history-substring-search
      # and autosuggest widgets do not exist yet and bindkey silently fails.
      (lib.mkAfter ''
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
        bindkey '^I'   autosuggest-accept
      '')
    ];
  };

  # The plugins are only present if the submodules were initialised. Sourcing
  # already prints to stderr at shell startup, but warn at activation too so it
  # is caught before you open a new terminal and wonder why nothing highlights.
  home.activation.checkZshPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for p in zsh-autosuggestions zsh-history-substring-search \
             zsh-syntax-highlighting zsh-you-should-use; do
      if [ -z "$(ls -A "${config.home.homeDirectory}/.mico/.config/zsh/$p" 2>/dev/null)" ]; then
        warnEcho "zsh plugin submodule '$p' is empty. Run: git -C ~/.mico submodule update --init --recursive"
      fi
    done
  '';
}
