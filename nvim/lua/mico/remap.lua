-- Default options
local opts = { noremap = true, silent = true }

vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', opts)

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- Window splits and navigationremap
vim.keymap.set("n", "vs", ":vs<CR>", { desc = 'Split the window vertically' })
vim.keymap.set("n", "sp", ":sp<CR>", { desc = 'Split the window horizontally' })
vim.keymap.set("n", "<C-L>", "<C-W>l", opts)
vim.keymap.set("n", "<C-H>", "<C-W>h", opts)
vim.keymap.set("n", "<C-K>", "<C-W>k", opts)
vim.keymap.set("n", "<C-J>", "<C-W>j", opts)

-- Miscellanious binds
vim.keymap.set("n", "J", "mzJ`z", opts)
vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)
vim.keymap.set("n", "n", "nzzzv", opts)
vim.keymap.set("n", "N", "Nzzzv", opts)
vim.keymap.set("n", "<CR>", "za", opts)

-- Highlight on yank
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
	callback = function()
		vim.highlight.on_yank()
	end,
	group = highlight_group,
	pattern = '*',
})

-- Document existing key chains
require('which-key').register {
	['<leader>c'] = { name = '[C]ode', _ = 'which_key_ignore' },
	['<leader>d'] = { name = '[D]atabase', _ = 'which_key_ignore' },
	['<leader>g'] = { name = '[G]it', _ = 'which_key_ignore' },
	['<leader>h'] = { name = 'Git [H]unk', _ = 'which_key_ignore' },
	['<leader>r'] = { name = '[R]ename', _ = 'which_key_ignore' },
	['<leader>s'] = { name = '[S]earch', _ = 'which_key_ignore' },
	['<leader>t'] = { name = '[T]oggle', _ = 'which_key_ignore' },
	['<leader>w'] = { name = '[W]orkspace', _ = 'which_key_ignore' },
	['<leader>o'] = { name = '[O]bsidian', _ = 'which_key_ignore' },
}
-- register which-key VISUAL mode
-- required for visual <leader>hs (hunk stage) to work
require('which-key').register({
	['<leader>'] = { name = 'VISUAL <leader>' },
	['<leader>h'] = { 'Git [H]unk' },
}, { mode = 'v' })

vim.keymap.set("v", ">", ">gv", opts)
vim.keymap.set("v", "<", "<gv", opts)
