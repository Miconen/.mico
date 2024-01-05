-- Disable word wrapping
vim.o.wrap = false

-- Set highlight on search
vim.o.hlsearch = false

-- Make line numbers default
vim.wo.number = true
vim.o.relativenumber = true

-- Enable mouse mode
vim.o.mouse = 'a'

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.o.clipboard = 'unnamedplus'

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true
-- Highlight search matches
vim.o.hlsearch = false

-- Keep signcolumn on by default
vim.wo.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250
vim.o.timeoutlen = 300

-- Set completeopt to have a better completion experience
vim.o.completeopt = 'menuone,noselect'

vim.o.termguicolors = true

-- Improve folding
vim.o.foldmethod = "indent"
vim.o.foldlevel = 99

-- Split Windows
vim.o.splitbelow = true
vim.o.splitright = true

-- Tabs and indentations
vim.o.tabstop = 4
vim.bo.tabstop = 4
vim.o.showtabline = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.bo.shiftwidth = 4
vim.o.smartindent = true
vim.bo.smartindent = true
vim.o.autoindent = true
vim.bo.autoindent = true
vim.o.expandtab = true
vim.bo.expandtab = true

vim.o.scrolloff = 10

vim.o.errorbells = false

-- Options based on filetypes
-- markdown
vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function()
		vim.opt.wrap = true
		vim.opt.linebreak = true
	end,
})
