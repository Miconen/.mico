# Check if ZELLIJ is set and not equal to 0
if [[ $ZELLIJ != 0 ]]; then
    zellij -l welcome
fi

# WSL specific configuration
if [[ $WSL_DISTRO_NAME != 0 ]]; then
    eval "$(/usr/sbin/wsl2-ssh-agent)"
    alias docker="podman"
fi

clear
fastfetch

if [[ uname == "Darwin" ]]; then
    source ~/.config/zsh/macos.sh || echo "Error: Could not source macOS settings."
fi

# Global settings file
source ~/.config/zsh/global.sh || echo "Error: Could not source global settings."
