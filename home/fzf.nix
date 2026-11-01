{
  lib,
  ...
}:
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    defaultCommand = "fd --hidden --strip-cwd-prefix --exclude .git";

    fileWidget = {
      command = "fd --hidden --strip-cwd-prefix --exclude .git";
      options = [ "--preview 'bat -n --color=always --line-range :500 {}'" ];
    };

    changeDirWidget = {
      command = "fd --type=d --hidden --strip-cwd-prefix --exclude .git";
      options = [ "--preview 'eza --tree --color=always {} | head -200'" ];
    };

    # Empty releases Ctrl-R to atuin (the supported way; non-empty would warn).
    historyWidget.command = "";

    # Catppuccin Mocha
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

  # 1300: after home-manager's aliases (1100), dirHashes (1150), highlighting (1200).
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
