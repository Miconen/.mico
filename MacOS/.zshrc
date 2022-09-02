# Plugins
source ~/Repos/zsh-autocomplete/zsh-autocomplete.plugin.zsh

# Path
ZSH="/usr/share/oh-my-zsh/"
export ZSH="/usr/share/oh-my-zsh/"
EDITOR=/opt/homebrew/Cellar/neovim/0.7.2_1/bin/nvim
export EDITOR=$EDITOR

# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Zoxide
eval "$(zoxide init zsh)"

# Prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b '
setopt PROMPT_SUBST
PROMPT='%F{white}%*%f %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f$ '

# Aliases
# Filepaths
alias .zshrc="$EDITOR ~/.zshrc"
alias .vimrc="$EDITOR ~/.config/nvim/init.lua"
alias .coc="$EDITOR ~/.config/coc/coc-settings.json"
alias .i3="$EDITOR ~/.config/i3/config"

# Utility
alias c="clear"
