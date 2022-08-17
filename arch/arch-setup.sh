#!/bin/sh
# zsh autocomplete
mkdir "$HOME"/Repos/
git clone --depth 1 -- https://github.com/marlonrichert/zsh-autocomplete.git "$HOME"/Repos/zsh-autocomplete

# aur helper, yay
git clone https://aur.archlinux.org/yay.git "$HOME"/Repos/yay
cd "$HOME"/Repos/yay/ && makepkg -si

# personal projects folder
mkdir "$HOME"/Code
# wallpapers folder that i3 uses 
mkdir "$HOME"/wallpapers
# configs
mkdir "$HOME"/.config

