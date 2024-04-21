# Check if ZELLIJ is set and not equal to 0
if [[ $ZELLIJ != 0 ]]; then
    zellij -l welcome
fi

clear
neofetch

if [[ uname == "Darwin" ]]; then
    source ~/.config/zsh/macos.sh || echo "Error: Could not source macOS settings."
fi

# Global settings file
source ~/.config/zsh/global.sh || echo "Error: Could not source global settings."
