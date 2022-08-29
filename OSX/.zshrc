# https://github.com/marlonrichert/zsh-autocomplete.git
source ~/Repos/zsh-autocomplete/zsh-autocomplete.plugin.zsh
ZSH="/usr/share/oh-my-zsh/"
export ZSH="/usr/share/oh-my-zsh/"
EDITOR=/usr/bin/nvim
export EDITOR=$EDITOR
plugins=(git)

# Prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b '
setopt PROMPT_SUBST
PROMPT='%F{white}%*%f %F{blue}%~%f %F{red}${vcs_info_msg_0_}%f$ '

# Zoxide
eval "$(zoxide init zsh)"

#ZSH_CACHE_DIR="$HOME/.cache/oh-my-zsh"
#if [[ ! -d "$ZSH_CACHE_DIR" ]]; then
  #mkdir "$ZSH_CACHE_DIR"
#fi

#source "$ZSH"/oh-my-zsh.sh

alias c="clear"

# Filepaths
alias .zshrc="$EDITOR ~/.zshrc"
alias .vimrc="$EDITOR ~/.config/nvim/init.lua"
alias .coc="$EDITOR ~/.config/coc/coc-settings.json"
alias .i3="$EDITOR ~/.config/i3/config"



echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/s2200708/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
