require('plugins')

vim.o.background = "dark"
vim.o.termguicolors = true
vim.api.nvim_set_var('gruvbox_contrast_dark', 'hard')
vim.api.nvim_set_var('gruvbox_invert_selection', '0')

vim.api.nvim_set_var('&t_8f', '<Esc>[38;2;%lu;%lu;%lum')
vim.api.nvim_set_var('&t_8f', '<Esc>[48;2;%lu;%lu;%lum')

vim.cmd([[colorscheme gruvbox]])
vim.cmd([[set guifont=Classic\ Console\ Neue:h11]])

vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Tab set to four spaces
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

local lsp = require('lsp-zero')

lsp.preset('recommended')
lsp.setup()
