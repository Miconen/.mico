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

    # Explicit: the default moves to $XDG_CONFIG_HOME/zsh at stateVersion 26.05.
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
      # `--icons=always` needs the `=`; with a space, `always` is read as a path.
      ls = "eza -lh --group-directories-first --icons=always";
      lsa = "ls -a";
      lt = "eza --tree --level=2 --long --icons=always --git";
      lta = "lt -a";
      ff = "fzf --preview 'bat --style=numbers --color=always {}'";
      cd = "z";

      # Configs
      zshconf = "nvim ${repoPath}/home/zsh.nix";
      nixconf = "nvim ${repoPath}/flake.nix";
      pkgconf = "nvim ${repoPath}/home/common.nix";
      nsearch = "nix search nixpkgs";
      nwhich = "nix-locate";
      ".vimrc" = "nvim ~/.config/nvim";
      nvimdiff = "nvim -d";
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

      # Containers
      docker = "podman";
      dcb = "docker compose up --build";
      api = "docker compose --profile dev up --build";
      dpurge = "podman compose down 2>/dev/null || true; podman rm -fa 2>/dev/null || true; podman network prune -f 2>/dev/null || true; systemctl --user restart podman.socket 2>/dev/null || true";
      ppurge = "dpurge";

      # Node
      bot = "set -a; source .env; set +a; go run ./cmd/bot";
      bot-test = "AUTH_KEY=123 LOG_LEVEL=silent npm run test";

      # Git
      gcm = "git commit -m";
      gcam = "git commit -a -m";
      gcad = "git commit -a --amend";

      # Zellij
      zf = "zellij action new-pane -f -- ";
      # zellij can't reload config, and session_serialization resurrects the old
      # layout, so kill the session; open a new terminal afterwards.
      zreload = "zellij delete-session --force main";
    };

    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        # Auto-start zellij. ZELLIJ_SKIP=1 gives a bare shell.
        if [[ -o interactive && -z "$ZELLIJ" && -z "$ZELLIJ_SKIP" && -z "$SSH_CONNECTION" && "$TERM" != "dumb" ]]; then
          if command -v zellij >/dev/null; then
            # One persistent session; layout comes from default_layout in config.kdl.
            exec zellij attach --create main
          fi
        fi
      '')

      # fzf-tab must load after compinit (570) but before autosuggestions (700),
      # so it can't be a programs.zsh.plugins entry (900).
      (lib.mkOrder 600 ''
        source ${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh
      '')

      (lib.mkOrder 1000 ''
        unsetopt menu_complete
        unsetopt flowcontrol
        setopt prompt_subst
        setopt always_to_end
        setopt auto_menu
        setopt complete_in_word
        setopt hist_verify
        setopt no_list_ambiguous
        setopt interactive_comments

        # Name the zellij tab after the current project.
        if [[ -n "$ZELLIJ" ]]; then
          autoload -Uz add-zsh-hook

          _mico_zellij_tab_name() {
            local root name tab_id
            root="$(git rev-parse --show-toplevel 2>/dev/null)" || root="$PWD"
            name="''${root:t}"
            [[ "$PWD" == "$HOME" ]] && name="~"
            [[ "$name" == "$_MICO_ZELLIJ_TAB" ]] && return 0
            # Plain rename-tab hits the FOCUSED tab; resolve this pane's own tab.
            tab_id="$(zellij action list-panes --json --tab 2>/dev/null \
              | ${pkgs.jq}/bin/jq -r --argjson id "$ZELLIJ_PANE_ID" \
                  '.[] | select(.is_plugin == false and .id == $id) | .tab_id')"
            [[ -n "$tab_id" ]] || return 0
            _MICO_ZELLIJ_TAB="$name"
            zellij action rename-tab --tab-id "$tab_id" "$name" 2>/dev/null
          }

          add-zsh-hook chpwd _mico_zellij_tab_name
          _mico_zellij_tab_name
        fi

        # fzf-tab requires the native menu off.
        zstyle ':completion:*' menu no
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
        zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'
        zstyle ':fzf-tab:complete:*:*' fzf-preview \
          '[[ -d $realpath ]] && eza -1 --color=always $realpath || bat --color=always --style=plain $realpath 2>/dev/null'
        zstyle ':fzf-tab:*' use-fzf-default-opts yes
        zstyle ':fzf-tab:*' switch-group '<' '>'
      '')

      # Last, so the plugin widgets exist before binding them.
      (lib.mkAfter ''
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
        bindkey '^I'   autosuggest-accept
      '')
    ];
  };
}
