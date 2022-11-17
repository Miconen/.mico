-- ???
vim.api.nvim_set_keymap("i", "<C-Space>", "coc#refresh()", { silent = true, expr = true })

-- Utility
vim.api.nvim_set_keymap("n", "<leader>.", "<Plug>(coc-codeaction)", {})
vim.api.nvim_set_keymap("n", "gd", "<Plug>(coc-definition)", {silent = true})
vim.api.nvim_set_keymap("n", "<leader>rn", "<Plug>(coc-rename)", {})
vim.api.nvim_set_keymap("n", "<leader>f", ":CocCommand prettier.formatFile<CR>", {noremap = true})
vim.api.nvim_set_keymap("n", "K", ":call CocActionAsync('doHover')<CR>", {silent = true, noremap = true})

-- Errors
vim.api.nvim_set_keymap("n", "<leader>l", ":CocCommand eslint.executeAutofix<CR>", {})
vim.api.nvim_set_keymap("n", "ge", "<Plug>(coc-diagnostic-next)", {})

-- Autocomplete menu keybinds
vim.api.nvim_set_keymap("i", "<TAB>", "coc#pum#visible() ? coc#pum#next(1) : '<TAB>'", {noremap = true, silent = true, expr = true})
vim.api.nvim_set_keymap("i", "<S-TAB>", "coc#pum#visible() ? coc#pum#prev(1) : '<S-TAB>'", {noremap = true, expr = true})

vim.api.nvim_set_keymap("i", "<CR>", "coc#pum#visible() ? coc#_select_confirm() : '<C-G>u<CR><C-R>=coc#on_enter()<CR>'", {silent = true, expr = true, noremap = true})

vim.o.hidden = true
vim.o.backup = false
vim.o.writebackup = false
vim.o.updatetime = 300
vim.g.coc_global_extensions = {
    -- Web dev
    "coc-html",
    "coc-htmlhint",
    "coc-emmet",
    "coc-css",
    "coc-html-css-support",
    -- JS / TS
    "coc-eslint",
    "coc-tsserver",
    "coc-json",
    -- Languages / Filetypes
    "coc-lua",
    "coc-sh",
    "coc-yaml",
    -- Productivity / Coding / Debug
    "coc-diagnostic",
    "coc-pairs",
    "coc-prettier",
    -- Misc
    "coc-docker",
    "coc-calc",
}
