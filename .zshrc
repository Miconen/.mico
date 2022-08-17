# https://github.com/marlonrichert/zsh-autocomplete.git
source ~/Repos/zsh-autocomplete/zsh-autocomplete.plugin.zsh
ZSH="/usr/share/oh-my-zsh/"
export ZSH="/usr/share/oh-my-zsh/"
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

# Filepaths
alias .zshrc="nvim ~/.zshrc"
alias .vimrc="nvim ~/.config/nvim/init.lua"
alias .coc="nvim ~/.config/coc/coc-settings.json"
alias .i3="nvim ~/.config/i3/config"
alias shared="cd /mnt/shared"
alias documents="cd /mnt/shared/documents"
alias pictures="cd /mnt/shared/pictures"
alias images="cd /mnt/shared/pictures"
alias videos="cd /mnt/shared/pictures"
alias music="cd /mnt/shared/pictures"
alias windows="cd /mnt/shared/windows"
alias linux="cd /mnt/shared/linux"
alias downloads="cd /mnt/shared/linux/Downloads"
alias fixscreens="bash ~/.config/.mico/arch/xrandr.sh"
alias addssh="bash ~/.config/.mico/arch/git-ssh-agent.sh"

ZSH_THEME=""
fpath+=$HOME/.local/share/oh-my-zsh/themes/typewritten
autoload -U promptinit; promptinit
prompt typewritten
