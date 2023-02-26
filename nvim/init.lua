-- Basic vim setup
require('basics')
-- Colors, theme and styling
require('colors')

-- Check and warn about missing dependencies
require('dependencies')

-- Plugin specific config files
require('telescope-config')
require('nvim-tree-config')
require('lsp-config')
require('nvim-cmp-config')
require('gitsigns-config')
require('scrollbar-config')
require('treesitter-config')
require('lualine').setup()

-- Imports of vim plugins
return require('plugins')
