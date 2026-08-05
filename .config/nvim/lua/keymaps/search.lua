-- keymaps/search.lua
local wk = require("which-key")
local map = vim.keymap.set

-- ── Group label ──────────────────────────────────────────────────────────────
wk.add({
	{ "<leader>s", group = " Search" },
	{ "<leader>sn", group = " Neovim configuration" },
})

-- ── Snacks picker ────────────────────────────────────────────────────────────
map("n", "<leader>sf", function()
	Snacks.picker.files()
end, { desc = "Files" })

map("n", "<leader>sF", function()
	Snacks.picker.files({ hidden = true })
end, { desc = "Files (hidden)" })

map("n", "<leader>sg", function()
	Snacks.picker.grep()
end, { desc = "Grep" })

map("n", "<leader>sG", function()
	Snacks.picker.grep({ hidden = true })
end, { desc = "Grep (hidden)" })

map("n", "<leader>sw", function()
	Snacks.picker.grep_word()
end, { desc = "Grep word under cursor" })

map("n", "<leader>sh", function()
	Snacks.picker.help()
end, { desc = "Help" })

map("n", "<leader>sk", function()
	Snacks.picker.keymaps()
end, { desc = "Keymaps" })

map("n", "<leader>sd", function()
	Snacks.picker.diagnostics()
end, { desc = "Diagnostics" })

map("n", "<leader>sr", function()
	Snacks.picker.recent()
end, { desc = "Recent files" })

map("n", "<leader>s<CR>", function()
	Snacks.picker.resume()
end, { desc = "Resume last search" })

map("n", "<leader>st", function()
	vim.cmd("TodoTelescope")
end, { desc = "Todo comments" })

map("n", "<leader>snf", function()
	Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Neovim config files" })
map("n", "<leader>sng", function()
	Snacks.picker.grep({ cwd = vim.fn.stdpath("config") })
end, { desc = "Grep neovim config" })

-- Fuzzy find in current buffer
map("n", "<leader>/", function()
	Snacks.picker.lines()
end, { desc = " Fuzzy search buffer" })

-- Fuzzy find across open buffers
map("n", "<leader>s/", function()
	Snacks.picker.grep({ buf = true })
end, { desc = "Grep open buffers" })
