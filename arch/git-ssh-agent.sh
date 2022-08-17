#!/bin/sh
eval "$(ssh-agent -s)"
ssh-add "$HOME"/.ssh/id_ed25519
