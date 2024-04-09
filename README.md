# .mico

## Dependencies

### Ubuntu / WSL
```bash
# System
sudo apt-get install zsh stow fd-find

# NeoVim
sudo apt update; sudo apt install --install-if-missing "yarn" "ranger" "rust-fd-find" "python-pynvim" "python-pytest" "delta" "rust-grcov" "rustup" "mingw-w64" "dotnet8" "monodevelop" "java-common" "nasm" "r-base" "rustc" "golang" "python" "ruby" "perl" "lua5.3" "kotlin" "elixir" "make" "nodejs" "npm" "node-typescript" "nuitka" "doxygen" "yard"; pip install "pyinstaller"; yarn global add "jest" "jsdoc" "typedoc"; go install "golang.org/x/tools/cmd/godoc@latest"; sudo snap install --classic "flutter"
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

```bash
:MasonInstall ansible-language-server angular-language-server asm-lsp asmfmt bash-debug-adapter bash-language-server checkmake codelldb clangd cmakelint csharpier debugpy delve docker-compose-language-service dockerfile-language-server elixir-ls eslint-lsp fantomas firefox-debug-adapter fsautocomplete golangci-lint golangci-lint-langserver gopls google-java-format helm-ls html-lsp java-test json-lsp jq jsonlint kotlin-debug-adapter kotlin-language-server ktlint lua-language-server markuplint matlab-language-server neocmakelsp netcoredbg omnisharp perlnavigator php-debug-adapter phpactor php-cs-fixer phpstan rubocop ruff ruff-lsp rust-analyzer selene shellcheck shfmt svelte-language-server stylua taplo typescript-language-server yaml-language-server yamllint yamlfmt zls
```

## Updating

To update the zsh plugins and nvim configuration submodules run this

```bash
git submodule update --recursive --remote
```
