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
rm -rf ~/.config/kitty/
ln -sf "$PWD/kitty/" ~/.config/

# Nvim config
rm -rf ~/.config/nvim/
ln -sf "$PWD/nvim/" ~/.config/

# zshrc
rm ~/.zshrc
ln -sf "$PWD/.zshrc" ~

echo 'Symlinked config files :)'
