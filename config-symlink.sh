#!/usr/bin/env bash
echo 'Running this script will overwrite your old kitty & nvim config files, consider backing them up before continuing!!!'
read -p "Continue and remove old config files? [Y/y]" -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
	echo 'Exited without changes'
	[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi

# Kitty config

kitty=~/.config/kitty/
if ! [ -L "$kitty" ] && ! [-e "$kitty"];
then
	echo "No existing symlink found for $kitty"
	rm -rf ~/.config/kitty/
fi
ln -sf "$PWD/kitty/" ~/.config/

# Nvim config
nvim=~/.config/nvim/
if ! [ -L "$nvim" ] && ! [-e "$nvim"];
then
	echo "No existing symlink found for $nvim"
	rm -rf ~/.config/nvim/
fi
ln -sf "$PWD/nvim/" ~/.config/

# zshrc
zsh=~/.config/zsh/
if ! [ -L "$zsh" ] && ! [-e "$zsh"];
then
	echo "No existing symlink found for $zsh"
	rm ~/.zshrc
fi
ln -sf "$PWD/.zshrc" ~

echo 'Symlinked config files :)'
