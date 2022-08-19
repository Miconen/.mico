# nvim-config
Repo containing my current neovim configuration
## Dependencies
- Neovim Nightly
- NodeJS
- [packer.nvim](https://github.com/wbthomason/packer.nvim)
- Any C compiler
## Installation
> Linux 
```sh
git clone https://github.com/Miconen/nvim-config.git ~/.config/nvim
```
> Windows Powershell
```ps1
git clone https://github.com/Miconen/nvim-config.git "$env:LOCALAPPDATA\nvim\"
```
### Nvim Install packages
```
:PackerSync
```
Optionally install LSP server for the languages of your choice.

### Bindings

**\<leader\>** = "\<Space/\>"

| Plugin    | Mapping      | Action                         |
| --------- | ------------ | ------------------------------ |
|           | \<C-H\>      | Move one split left            |
|           | \<C-J\>      | Move one split down            |
|           | \<C-K\>      | Move one split up              |
|           | \<C-L\>      | Move one split right           |
|           | \<C-N\>      | Open file explorer             |
|           | \<C-S\>      | Open search & replace          |
|           | \<leader-t\> | Open a terminal buffer         |
|           | sp           | Split window horizontally      |
|           | tj           | Move one tab left              |
|           | tk           | Move one tab right             |
|           | tn           | Create a new tab               |
|           | to           | Close all other tabs           |
|           | vs           | Split window vertically        |
| coc       | K            | Hover over symbol              |
| coc       | \<C-Space\>  | Open autocompletion            |
| coc       | \<CR\>       | Select autocompletion          |
| coc       | \<S-TAB\>    | Browse previous autocompletion |
| coc       | \<TAB\>      | Browse next autocompletion     |
| coc       | \<leader\>.  | Open code actions              |
| coc       | \<leader\>f  | Format file with prettier      |
| coc       | \<leader\>l  | Execute code autofix           |
| coc       | \<leader\>rn | Rename symbol                  |
| coc       | gd           | Go to definition               |
| coc       | ge           | Go to next error               |
| Telescope | \<C-B\>      | Open buffer picker             |
| Telescope | \<C-F\>      | Open project search            |
| Telescope | \<C-P\>      | Open file picker               |

### Credits

nvim config is a modification of [https://github.com/albingroen/quick.nvim](https://github.com/albingroen/quick.nvim)
