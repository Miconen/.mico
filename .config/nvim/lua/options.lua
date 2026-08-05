-- options.lua

vim.g.have_nerd_font = true
vim.g.icons_enabled = true

-- Appearance
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.showmode = false
vim.opt.showtabline = 0
vim.opt.laststatus = 3            -- global statusline
vim.opt.fillchars = { eob = " " } -- hide ~ on empty lines
vim.opt.colorcolumn = "80"

-- Editing
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.smartindent = true
vim.opt.breakindent = true
vim.opt.linebreak = true
vim.opt.wrap = true
vim.opt.copyindent = true
vim.opt.preserveindent = true

-- Search
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.inccommand = "split"

-- Splits
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Scrolling
vim.opt.scrolloff = 999 -- keep cursor centered vertically
vim.opt.sidescrolloff = 8
vim.opt.mousescroll = "ver:1,hor:0"
vim.opt.selection = "old"

-- Folds (for nvim-ufo or native)
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldcolumn = "0"

-- Completion
vim.opt.completeopt = { "menu", "menuone", "noselect" }
vim.opt.pumheight = 10

-- Misc
vim.opt.mouse = "a"
vim.opt.fileencoding = "utf-8"
vim.opt.undofile = true
vim.opt.swapfile = false
vim.opt.writebackup = false
vim.opt.timeoutlen = 350
vim.opt.updatetime = 250
vim.opt.history = 1000
vim.opt.shada = "!,'1000,<50,s10,h"
vim.opt.virtualedit = "block"
vim.opt.cmdheight = 0
vim.opt.list = true
vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
vim.opt.guicursor = "n:blinkon200,i-ci-ve:ver25"
vim.opt.autochdir = false
vim.opt.diffopt:append({ "algorithm:histogram", "linematch:60" })
vim.opt.shortmess:append({ s = true, I = true })
vim.opt.backspace:append({ "nostop" })
vim.opt.viewoptions:remove("curdir")

vim.schedule(function()
  vim.opt.clipboard = "unnamedplus"
end)
