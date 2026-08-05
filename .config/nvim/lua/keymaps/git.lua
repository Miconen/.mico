-- keymaps/git.lua
local wk = require("which-key")
local map = vim.keymap.set
local icons = require("keymaps.icons")

wk.add({
	{ "<leader>g", group = icons.Git .. " Git" },
	{ "<leader>gt", group = "Toggles" },
})

map("n", "<leader>gz", function()
	Snacks.lazygit.open()
end, { desc = "Lazygit" })
map("n", "<leader>gb", function()
	Snacks.gitbrowse.open()
end, { desc = "Browse repo in browser" })
map("n", "<leader>gB", function()
	Snacks.git.blame_line()
end, { desc = "Blame line" })

map("n", "]h", function()
	if vim.wo.diff then
		vim.cmd.normal({ "]c", bang = true })
	else
		require("mini.diff").goto_hunk("next")
	end
end, { desc = "Next hunk" })

map("n", "[h", function()
	if vim.wo.diff then
		vim.cmd.normal({ "[c", bang = true })
	else
		require("mini.diff").goto_hunk("prev")
	end
end, { desc = "Previous hunk" })

map("n", "<leader>gs", function()
	require("mini.diff").operator("apply", { scope = "hunk" })
end, { desc = "Stage hunk" })

map("n", "<leader>gS", function()
	require("mini.diff").operator("apply", { scope = "file" })
end, { desc = "Stage file" })

map("n", "<leader>gu", function()
	require("mini.diff").operator("reset", { scope = "hunk" })
end, { desc = "Reset (unstage) hunk" })

map("n", "<leader>gp", function()
	require("mini.diff").toggle_overlay(0)
end, { desc = "Preview diff overlay" })

map("v", "<leader>gs", function()
	require("mini.diff").operator("apply")
end, { desc = "Stage selection" })

Snacks.toggle
	.new({
		name = "Diff overlay",
		get = function()
			return vim.b.minidiff_overlay ~= nil and vim.b.minidiff_overlay
		end,
		set = function()
			require("mini.diff").toggle_overlay(0)
		end,
	})
	:map("<leader>gtd")
