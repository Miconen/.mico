-- Basic vim setup
require('basics')
-- Colors, theme and styling
require('colors')
-- Plugin specific config files
require('telescope-config')
require('lsp-config')
require('nvim-cmp')
require('gitsigns-config')
require('scrollbar-config')
require('treesitter-config')
require('lualine').setup()

-- Imports of vim plugins
return require('plugins')
