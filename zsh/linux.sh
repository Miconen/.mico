# Path
EDITOR=/usr/bin/nvim
export EDITOR=$EDITOR

# Aliases
# Configs
alias .i3="$EDITOR ~/.config/i3/config"

# Filepaths
alias shared="cd /mnt/shared"
alias documents="cd /mnt/shared/documents"
alias pictures="cd /mnt/shared/pictures"
alias images="cd /mnt/shared/pictures"
alias videos="cd /mnt/shared/pictures"
alias music="cd /mnt/shared/pictures"
alias windows="cd /mnt/shared/windows"
alias linux="cd /mnt/shared/linux"
alias downloads="cd /mnt/shared/linux/Downloads"

# Utility
alias fixscreens="bash ~/.config/.mico/arch/xrandr.sh"
alias addssh="bash ~/.config/.mico/arch/git-ssh-agent.sh"
alias yeet="yay -Rn"
alias yeeet="yay -Rns"
alias yeet_useless="yay -Rns $(yay -Qtdq)"
alias files="nemo"
alias files.="nemo ."
