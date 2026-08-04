{
  pkgs,
  lib,
  config,
  repoPath,
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

    syntaxHighlighting.enable = true;

    autosuggestion = {
      enable = true;
      strategy = [
        "history"
        "completion"
      ];
    };

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

    # home-manager has no `historySubstringSearch` option, so these two are
    # explicit plugin entries. `file` is relative to the package root.
    # Sourced at order 900, before aliases (1100) and highlighting (1200).
    plugins = [
      {
        name = "zsh-history-substring-search";
        src = pkgs.zsh-history-substring-search;
        file = "share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.plugin.zsh";
      }
      {
        name = "you-should-use";
        src = pkgs.zsh-you-should-use;
        file = "share/zsh/plugins/you-should-use/you-should-use.plugin.zsh";
      }
    ];

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
      zshconf = "nvim ${repoPath}/home/zsh.nix";
      nixconf = "nvim ${repoPath}/flake.nix";
      ".vimrc" = "nvim ~/.config/nvim";
      nvimdiff = "nvim -d";
      # Structural diff. delta stays the git pager; this is for "what actually
      # changed", ignoring reformatting.
      dft = "difft";
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
            # attach --create reuses one persistent session instead of starting a
            # fresh one per terminal, which is what makes session_serialization
            # in config.kdl actually do anything. The layout comes from
            # `default_layout "default"` in config.kdl, because attach --create
            # does not accept --layout. Downside: a wedged session follows you
            # until `zellij kill-session main`.
            exec zellij attach --create main
          fi
        fi
      '')

      # ---- order 600: fzf-tab ------------------------------------------------
      # Order is load-bearing and narrow. fzf-tab must come after compinit
      # (home-manager runs that at 570) but BEFORE anything that wraps
      # completion widgets. home-manager sources zsh-autosuggestions at 700, and
      # `programs.zsh.plugins` entries at 900 - so declaring fzf-tab as a plugin
      # would load it too late and it would silently do nothing.
      (lib.mkOrder 600 ''
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      '')

      # ---- order 1000: general config ---------------------------------------
      (lib.mkOrder 1000 ''
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

        # fzf-tab requires the native menu to be OFF; `menu select` fights it and
        # the two together break completion entirely.
        zstyle ':completion:*' menu no
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

        # fzf-tab previews
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
        zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'
        zstyle ':fzf-tab:complete:*:*' fzf-preview \
          '[[ -d $realpath ]] && eza -1 --color=always $realpath || bat --color=always --style=plain $realpath 2>/dev/null'
        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        zstyle ':fzf-tab:*' switch-group '<' '>'
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
}
