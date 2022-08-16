ZSH="/usr/share/oh-my-zsh/"
export ZSH="/usr/share/oh-my-zsh/"
ZSH_THEME=""
plugins=(git)

# Zoxide
eval "$(zoxide init zsh)"

#ZSH_CACHE_DIR="$HOME/.cache/oh-my-zsh"
#if [[ ! -d "$ZSH_CACHE_DIR" ]]; then
  #mkdir "$ZSH_CACHE_DIR"
#fi

#source "$ZSH"/oh-my-zsh.sh

alias yeet="yay -Rn"
alias yeeet="yay -Rns"
alias yeet_useless="yay -Rns $(yay -Qtdq)"

alias files="nemo"
alias files.="nemo ."

alias c="clear"

# Dotfiles
alias .zshrc="nvim ~/.zshrc"
alias .vimrc="nvim ~/.config/nvim/init.lua"
alias .i3="nvim ~/.config/i3/config"

fpath+=$HOME/.local/share/oh-my-zsh/themes/typewritten
autoload -U promptinit; promptinit
prompt typewritten
