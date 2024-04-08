case `uname` in
    # Linux settings file
    Linux )
        source ~/.config/zsh/linux.sh
    ;;
    # MacOS settigs file
    Darwin )
        source ~/.config/zsh/macos.sh
    ;;
esac

# Global settings file
source ~/.config/zsh/global.sh
