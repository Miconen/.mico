# .mico

## Dependencies

### Ubuntu / WSL

#### System
```bash
sudo apt install zsh stow fd-find fzf keychain neofetch zoxide unzip ripgrep && sudo snap install nvim --classic
```

#### Lazygit
```bash
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
```

#### NeoVim
```bash
sudo apt update; sudo apt install --install-if-missing "yarn" "ranger" "rust-fd-find" "python-pynvim" "python-pytest" "delta" "rust-grcov" "rustup" "mingw-w64" "dotnet8" "monodevelop" "java-common" "nasm" "r-base" "rustc" "golang" "python" "ruby" "perl" "lua5.3" "kotlin" "elixir" "make" "nodejs" "npm" "node-typescript" "nuitka" "doxygen" "yard"; pip install "pyinstaller"; yarn global add "jest" "jsdoc" "typedoc"; go install "golang.org/x/tools/cmd/godoc@latest"; sudo snap install --classic "flutter"
```

### macOS

#### System
```bash
sudo brew install stow zsh fd fzf neofetch zoxide unzip ripgrep neovim jesseduffield/lazygit/lazygit jesseduffield/lazydocker/lazydocker
```

#### NeoVim

I personally prefer to use [Maple Mono NF](https://github.com/subframe7536/maple-font) as my font.

```bash
brew install "ranger" "fd" "git-delta" "rustup-init" "yarn" "mingw-w64" "dotnet" "mono" "openjdk" "dart-sdk" "kotlin" "elixir" "node" "typescript" "make" "rust" "go" "nasm" "r" "ruby" "perl" "lua" "swift" "pyinstaller" "doxygen"; sudo brew install --cask "dotnet-sdk" "flutter"; pip install "pynvim" "pytest" "Nuitka"; yarn add global "jest" "jsdoc" "typedoc"; cargo install "cargo-nextest" "grcov"; go install "golang.org/x/tools/cmd/godoc@latest"
```

## Installation

### Configuration files

```bash
git clone --recursive -j8 git@github.com:Miconen/.mico.git ~/.mico

cd ~/.mico

# Apply symlinks to dotfiles
stow .

# or...

# Force apply symlinks to dotfiles (destructive)
stow --adopt .
```

### Git config

```bash
git config --file .gitconfig.local user.name <username>
git config --file .gitconfig.local user.email <email>
```

### Mason (NeoVim)
```bash
:MasonInstall ansible-language-server angular-language-server asm-lsp asmfmt bash-debug-adapter bash-language-server checkmake codelldb clangd cmakelint csharpier debugpy delve docker-compose-language-service dockerfile-language-server elixir-ls eslint-lsp fantomas firefox-debug-adapter fsautocomplete golangci-lint golangci-lint-langserver gopls google-java-format helm-ls html-lsp java-test json-lsp jq jsonlint kotlin-debug-adapter kotlin-language-server ktlint lua-language-server markuplint matlab-language-server neocmakelsp netcoredbg omnisharp perlnavigator php-debug-adapter phpactor php-cs-fixer phpstan rubocop ruff ruff-lsp rust-analyzer selene shellcheck shfmt svelte-language-server stylua taplo typescript-language-server yaml-language-server yamllint yamlfmt zls
```

## Updating

To update the zsh plugins and nvim configuration submodules run this

```bash
git submodule update --recursive --remote
```
