# Path
EDITOR=/usr/bin/nvim
export EDITOR=$EDITOR
SHARED=/mnt/shared
export SHARED=$SHARED

# Aliases
# Configs
alias .i3="$EDITOR ~/.config/i3/config"

# Filepaths
alias shared="cd /mnt/shared"
alias documents="cd /mnt/shared/Documents"
alias pictures="cd /mnt/shared/Pictures"
alias images="cd /mnt/shared/Pictures"
alias videos="cd /mnt/shared/Pictures"
alias music="cd mnt/shared/Pictures"
alias windows="cd /mnt/shared/Windows"
alias linux="cd /mnt/shared/Linux"
alias downloads="cd /mnt/shared/Linux/Downloads"

# Utility
alias fixscreens="bash ~/.config/.mico/arch/xrandr.sh"
alias addssh="bash ~/.config/.mico/arch/git-ssh-agent.sh"
alias yeet="yay -Rn"
alias yeeet="yay -Rns"
alias yeet_useless="yay -Rns $(yay -Qtdq)"
alias files="ranger"
alias files.="ranger ."
