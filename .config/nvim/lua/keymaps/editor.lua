local wk = require("which-key")
local map = vim.keymap.set
local icons = require("keymaps.icons")

wk.add({
	{ "<leader>n", group = icons.Notes .. " Notes" },
	{ "<leader>w", group = icons.Window .. " Windows" },
})

map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })

-- Splits live under <leader>w so `s` stays free for flash.
map("n", "<leader>ws", "<cmd>split<cr>", { desc = "Horizontal split" })
map("n", "<leader>wv", "<cmd>vsplit<cr>", { desc = "Vertical split" })
map("n", "<leader>wc", "<cmd>close<cr>", { desc = "Close window" })
map("n", "<leader>wo", "<cmd>only<cr>", { desc = "Close other windows" })
map("n", "<leader>w=", "<C-w>=", { desc = "Balance windows" })

map("n", "<leader>wdf", function()
	Snacks.picker.files({
		prompt = "Diff with File ❯ ",
		confirm = function(picker, item)
			picker:close()
			if item and item.file then
				vim.cmd("vertical diffsplit " .. vim.fn.fnameescape(item.file))
			end
		end,
	})
end, { desc = "Diff current buffer with file" })

map("n", "<leader>wdb", function()
	Snacks.picker.buffers({
		prompt = "Diff with Buffer ❯ ",
		confirm = function(picker, item)
			picker:close()
			if item and item.file then
				vim.cmd("vertical diffsplit " .. vim.fn.fnameescape(item.file))
			end
		end,
	})
end, { desc = "Diff current buffer with open buffer" })

map("n", "<leader>wdt", "<cmd>windo diffthis<cr>", { desc = "Diff all open splits" })
map("n", "<leader>wdq", "<cmd>windo diffoff<cr>", { desc = "Stop diff (diffoff)" })

map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = icons.Search .. " Quickfix diagnostics" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })
map("v", "J", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

map("n", "-", function()
	local mf = require("mini.files")
	if not mf.close() then
		mf.open(vim.api.nvim_buf_get_name(0), false)
		vim.schedule(function()
			mf.reveal_cwd()
		end)
	end
end, { desc = "Toggle file explorer" })

map("n", "<leader>nn", function()
	Snacks.scratch()
end, { desc = "Toggle scratch buffer" })
map("n", "<leader>ns", function()
	Snacks.scratch.select()
end, { desc = "Select scratch buffer" })

map("n", "]t", function()
	require("todo-comments").jump_next()
end, { desc = "Next todo comment" })
map("n", "[t", function()
	require("todo-comments").jump_prev()
end, { desc = "Previous todo comment" })
