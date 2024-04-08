# .mico

## Dependencies

### Ubuntu / WSL
```bash
sudo apt-get install zsh stow
```

## Installation

```bash
git clone --recurse-submodules -j8 git@github.com:Miconen/.mico.git ~/.mico

cd ~/.mico

# Apply symlinks to dotfiles
stow .

# or...

# Force apply symlinks to dotfiles (destructive)
stow --adopt .
```

## Updating

To update the zsh plugins and nvim configuration submodules run this

```bash
git submodule update --recursive --remote
```
