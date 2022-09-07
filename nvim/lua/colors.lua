-- Gruvbox Dark
-- vim.o.background = "dark"
-- vim.cmd([[colorscheme gruvbox]])

-- Tokyonight, transparent
vim.o.termguicolors = true
vim.g.tokyonight_transparent = true
vim.g.tokyonight_lualine_bold = true
vim.cmd([[ colorscheme tokyonight ]])
vim.cmd([[ silent! highlight Normal guibg=none ]])
