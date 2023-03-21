-- Tokyonight, transparent
require("tokyonight").setup {
    style = "night", -- The theme comes in three styles, `storm`, `moon`, a darker variant `night` and `day`
    transparent = true, -- Enable this to disable setting the background color
    terminal_colors = true, -- Configure the colors used when opening a `:terminal` in Neovim
    sidebars = { "qf", "help", "terminal" }, -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
}
vim.o.termguicolors = true
vim.g.tokyonight_lualine_bold = true
vim.cmd([[ colorscheme tokyonight ]])
vim.cmd([[ silent! highlight Normal guibg=none ]])

require("indent_blankline").setup {
    space_char_blankline = " ",
    show_current_context = true,
    show_current_context_start = true,
}
