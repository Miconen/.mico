-- keymaps/editor.lua
local wk = require("which-key")
local map = vim.keymap.set

-- ── Group labels ────────────────────────────────────────────────────────────
wk.add({
	{ "<leader>n", group = "󰅌 Notes" },
})

-- ── Window navigation ────────────────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })

-- ── Splits ───────────────────────────────────────────────────────────────────
map("n", "vs", "<cmd>vsplit<cr>", { desc = "Vertical split" })
map("n", "sp", "<cmd>split<cr>", { desc = "Horizontal split" })

-- ── Misc editing ─────────────────────────────────────────────────────────────
map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = " Quickfix diagnostics" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Keep visual selection when indenting
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- Move lines up/down in visual mode
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

-- ── File explorer (mini.files) ───────────────────────────────────────────────
map("n", "-", function()
	local mf = require("mini.files")
	if not mf.close() then
		mf.open(vim.api.nvim_buf_get_name(0), false)
		vim.schedule(function()
			mf.reveal_cwd()
		end)
	end
end, { desc = "Toggle file explorer" })

-- ── Scratch / notes (snacks) ─────────────────────────────────────────────────
map("n", "<leader>nn", function()
	Snacks.scratch()
end, { desc = "Toggle scratch buffer" })
map("n", "<leader>ns", function()
	Snacks.scratch.select()
end, { desc = "Select scratch buffer" })

-- ── Todo comments ────────────────────────────────────────────────────────────
map("n", "]t", function()
	require("todo-comments").jump_next()
end, { desc = "Next todo comment" })
map("n", "[t", function()
	require("todo-comments").jump_prev()
end, { desc = "Previous todo comment" })
