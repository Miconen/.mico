#!/usr/bin/env bash
echo 'Running this script will overwrite your old kitty & nvim config files, consider backing them up before continuing!!!'
read -p "Continue and remove old config files? [Y/y]" -n 1 -r
echo    # (optional) move to a new line
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
	echo 'Exited without changes'
	[[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1 # handle exits from shell or function but don't exit interactive shell
fi

prepare_folder () {
	echo "Preparing"
	if ! [[ -L "$1" ]];
	then
		echo "Removing"
		rm -rf "$1"
	fi
}

symlink_folder () {
	# Remove old folders if not yet linked
	prepare_folder "$1"
	# Link folders
	echo "Linking"
	ln -sf "$2" "$3"
}

# Kitty config
symlink_folder "~/.config/kitty/" "$PWD/kitty/" "~/.config/"
# Nvim config
symlink_folder "~/.config/nvim/" "$PWD/nvim/" "~/.config/"
# zshrc
symlink_folder "~/.zshrc" "$PWD/.zshrc" "~"

echo 'Symlinked config files :)'
