#!/bin/sh
# system update
sudo pacman -Sy --noconfirm archlinux-keyring
sudo pacman --noconfirm -Syu
sudo pacman -S --noconfirm --needed base-devel wget git curl

