# zsh config

## Usage

Source the zshrc.sh file in this folder inside your actual .zshrc or use the config-installer.sh script.

```zsh
source ~/.config/.mico/zsh/zshrc.sh
```

### Configuration

Adding global, cross-platform configuration goes inside the global.sh. Linux and MacOS specific configuration should go in the linux.sh and macos.sh files respectively. These will be autoloaded correctly on each platform.
