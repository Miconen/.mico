# https://github.com/marlonrichert/zsh-autocomplete.git
source ~/Repos/zsh-autocomplete/zsh-autocomplete.plugin.zsh
EDITOR=$EDITOR
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

alias yeet="yay -Rn"
alias yeeet="yay -Rns"
alias yeet_useless="yay -Rns $(yay -Qtdq)"

alias files="nemo"
alias files.="nemo ."

alias c="clear"

# Filepaths
alias .zshrc="$EDITOR ~/.zshrc"
alias .vimrc="$EDITOR ~/.config/nvim/init.lua"
alias .coc="$EDITOR ~/.config/coc/coc-settings.json"
alias .i3="$EDITOR ~/.config/i3/config"
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
