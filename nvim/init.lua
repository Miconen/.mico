vim.loader.enable()

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- [[ Install `lazy.nvim` plugin manager ]]
require('mico.lazy')

local plugins = require('mico.plugin-list')
require('lazy').setup(plugins, {})

-- [[ Setting options ]]
require('mico.settings')
require('mico.colors')

-- [[ Basic Keymaps ]]
require('mico.remap')

-- [[ Configure Telescope ]]
require('mico.telescope')

-- [[ Configure Treesitter ]]
require('mico.treesitter')

-- [[ Configure LSP ]]
require('mico.lsp')

-- [[ Configure nvim-cmp ]]
require('mico.cmp')

-- The line beneath this is called `modeline`. See `:help modeline`
-- vim: ts=2 sts=2 sw=2 et
