#!/bin/bash

# Get explicitly installed packages and strip version numbers
pacman -Qe | cut -d' ' -f1 > "$HOME/packages/packages.txt"
