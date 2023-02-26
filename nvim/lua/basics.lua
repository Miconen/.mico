vim.g.mapleader = " "
vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = false
vim.o.expandtab = true
vim.o.incsearch = true
vim.o.tabstop = 4
vim.o.cursorline = true
vim.o.ignorecase = true
vim.o.hlsearch = false
vim.o.swapfile = false
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.scrolloff = 10
vim.o.errorbells = false
vim.o.shiftwidth = 4
vim.o.numberwidth = 4
vim.o.showmode = false
vim.o.showtabline = 2
vim.o.signcolumn = 'yes'
vim.o.mouse = 'a'

vim.notify = require("notify")

local opts = { noremap = true, silent = true }
vim.keymap.set('i', '<NL>', '<C-o>o', opts) -- <NL> is basically <C-CR>
vim.keymap.set('n', 'vs', ':vs<CR>', opts)
vim.keymap.set('n', 'sp', ':sp<CR>', opts)
vim.keymap.set('n', '<C-L>', '<C-W><C-L>', opts)
vim.keymap.set('n', '<C-H>', '<C-W><C-H>', opts)
vim.keymap.set('n', '<C-K>', '<C-W><C-K>', opts)
vim.keymap.set('n', '<C-J>', '<C-W><C-J>', opts)
vim.keymap.set('n', 'tn', ':tabnew<CR>', opts)
vim.keymap.set('n', 'tk', ':tabnext<CR>', opts)
vim.keymap.set('n', 'tj', ':tabprev<CR>', opts)
vim.keymap.set('n', 'to', ':tabo<CR>', opts)
vim.keymap.set('n', '<C-S>', ':%s/', opts)
vim.keymap.set("n", "<leader>t", ":sp<CR> :term<CR> :resize 15N<CR> :setlocal nonumber norelativenumber<CR> i", opts)
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", opts)
-- Set block level indenting to tab & shift-tab, also retain selection after motion
vim.keymap.set('v', '>', '>gv', opts)
vim.keymap.set('v', '<', '<gv', opts)
-- Set shared clipboard between os and nvim
vim.o.clipboard = vim.o.clipboard .. "unnamedplus"

vim.cmd([[
  augroup WindowManagement
    autocmd!
    autocmd WinEnter * call Handle_Win_Enter()
  augroup END

  function! Handle_Win_Enter()
    setlocal winhighlight=Normal:ActiveWindow,NormalNC:InactiveWindow
    highlight SignColumn guibg=Normal:ActiveWindow,NormalNC:InactiveWindow
  endfunction
]])
