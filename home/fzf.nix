{
  lib,
  ...
}:
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    # Use fd rather than find. Note the old config also aliased `fd=fdfind`,
    # a Debian-only binary name that broke fd entirely on Arch. Removed.
    defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";

    fileWidget = {
      command = "fd --hidden --strip-cwd-prefix --exclude .git";
      options = [ "--preview 'bat -n --color=always --line-range :500 {}'" ];
    };

    changeDirWidget = {
      command = "fd --type=d --hidden --strip-cwd-prefix --exclude .git";
      options = [ "--preview 'eza --tree --color=always {} | head -200'" ];
    };

    # Hand Ctrl-R to atuin. An empty command is the documented, supported way to
    # release the binding to a history manager - upstream names Atuin explicitly.
    # Setting a non-empty custom command instead would print a startup warning.
    historyWidget.command = "";

    # Catppuccin Mocha, replacing the hand-rolled blue palette in the old
    # .config/zsh/fzf.sh.
    colors = {
      "bg+" = "#313244";
      "bg" = "#1e1e2e";
      "spinner" = "#f5e0dc";
      "hl" = "#f38ba8";
      "fg" = "#cdd6f4";
      "header" = "#f38ba8";
      "info" = "#cba6f7";
      "pointer" = "#f5e0dc";
      "marker" = "#b4befe";
      "fg+" = "#cdd6f4";
      "prompt" = "#cba6f7";
      "hl+" = "#f38ba8";
      "selected-bg" = "#45475a";
      "border" = "#6c7086";
      "label" = "#cdd6f4";
    };
  };

  # Completion helpers from the old fzf.sh. These are shell functions, so they
  # have to be injected into zshrc rather than expressed as fzf options.
  #
  # Order 1300 on purpose: home-manager already uses 1100 for shellAliases,
  # 1150 for dirHashes and 1200 for syntax highlighting.
  programs.zsh.initContent = lib.mkOrder 1300 ''
    _fzf_compgen_path() {
      fd --hidden --exclude .git . "$1"
    }

    _fzf_compgen_dir() {
      fd --type=d --hidden --exclude .git . "$1"
    }

    _fzf_comprun() {
      local command=$1
      shift

      case "$command" in
        cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
        export|unset) fzf --preview "eval 'echo \$'{}"                         "$@" ;;
        ssh)          fzf --preview 'dig {}'                                   "$@" ;;
        *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
      esac
    }
  '';
}
