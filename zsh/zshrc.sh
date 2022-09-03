# Global settings file
# Plugins
source ~/Repos/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# Zoxide
eval "$(zoxide init zsh)"

# Prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b '
setopt PROMPT_SUBST
PROMPT='%F{white}%*%f %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f$ '

# Aliases
# Configs
alias .zshrc="$EDITOR ~/.config/.mico/zsh/zshrc.sh"
alias .vimrc="$EDITOR ~/.config/nvim/init.lua"
alias .coc="$EDITOR ~/.config/nvim/coc-settings.json"

# Utility
alias :q=exit
alias c="clear"

case `uname` in
    # Linux settings file
    Linux)
        source ~/.config/.mico/zsh/linux.sh
    ;;
    # MacOS settigs file
    Darwin)
        source ~/.config/.mico/zsh/macos.sh
    ;;
esac
