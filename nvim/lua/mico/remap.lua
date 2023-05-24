local opts = { noremap = true, silent = true }
vim.keymap.set("i", "<NL>", "<C-o>o", opts) -- <NL> is basically <C-CR>

vim.keymap.set("n", "vs", ":vs<CR>", opts)
vim.keymap.set("n", "sp", ":sp<CR>", opts)
vim.keymap.set("n", "<C-L>", "<C-W><C-L>", opts)
vim.keymap.set("n", "<C-H>", "<C-W><C-H>", opts)
vim.keymap.set("n", "<C-K>", "<C-W><C-K>", opts)
vim.keymap.set("n", "<C-J>", "<C-W><C-J>", opts)
vim.keymap.set("n", "tn", ":tabnew<CR>", opts)
vim.keymap.set("n", "tk", ":tabnext<CR>", opts)
vim.keymap.set("n", "tj", ":tabprev<CR>", opts)
vim.keymap.set("n", "to", ":tabo<CR>", opts)
vim.keymap.set("n", "<C-S>", ":%s/", opts)
vim.keymap.set("n", "<leader>t", ":sp<CR> :term<CR> :resize 15N<CR> :setlocal nonumber norelativenumber<CR> i", opts)
vim.keymap.set("n", "J", "mzJ`z", opts)
vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)
vim.keymap.set("n", "n", "nzzzv", opts)
vim.keymap.set("n", "N", "Nzzzv", opts)
vim.keymap.set("n", "<leader>d", '"_d', opts)
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz", opts)
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz", opts)
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", opts)
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", opts)
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], opts)

vim.keymap.set("x", "<leader>p", '"+y', opts)

vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", opts)

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", opts)
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", opts)
vim.keymap.set("v", ">", ">gv", opts)
vim.keymap.set("v", "<", "<gv", opts)
vim.keymap.set("v", "<leader>d", '"_d', opts)
-- Set shared clipboard between os and nvim
vim.o.clipboard = vim.o.clipboard .. "unnamedplus"
-- Windows support for help
vim.o.keywordprg = ":help"

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
