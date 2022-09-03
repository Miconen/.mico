source ~/.config/.mico/zsh/global.sh

case `uname` in
    # Linux settings file
    Linux)
        source ~/.config/.mico/zsh/linux.sh
    ;;
    # MacOS settigs file
    Darwin)
        source ~/.config/.mico/zsh/macos.sh
    ;;
esac
