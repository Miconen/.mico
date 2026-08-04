# Start Zellij
if [[ -z "$ZELLIJ" ]]; then
    exec zellij --layout default
fi

# WSL specific configuration
if [[ -n "$WSL_DISTRO_NAME" && -o interactive && -x /usr/sbin/wsl2-ssh-agent ]]; then
    eval "$(/usr/sbin/wsl2-ssh-agent)"
    alias docker="podman"
fi

if [[ -o interactive && -z "$ZELLIJ" ]]; then
    clear
    fastfetch
fi

# Global settings file
source ~/.config/zsh/global.sh || echo "Error: Could not source global settings."
