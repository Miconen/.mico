return {
	"epwalsh/obsidian.nvim",
	event = "VeryLazy",
	version = "*",
	-- lazy = true,
	-- ft = "markdown",
	dependencies = {
		"nvim-lua/plenary.nvim",
		'nvim-treesitter/nvim-treesitter',
	},
	opts = {
		workspaces = {
			{
				name = "mico",
				path = "D:/Documents/Obsidian/mico",
			},
			{
				name = "tectonic",
				path = "D:/Documents/Obsidian/tectonic",
			},
		},
	},

	completion = {
		nvim_cmp = true,
		min_chars = 2,
		new_notes_location = "current_dir",
		prepend_note_id = true,
		prepend_note_path = false,
		use_path_only = false,
	},

	vim.keymap.set("n", "<leader>ose", ":ObsidianSearch<CR>", { desc = 'Search for Obsidian md note' }),
	vim.keymap.set("n", "<leader>osw", ":ObsidianQuickSwitch<CR>", { desc = 'Switch between Obsidian md note' }),
	vim.keymap.set("n", "<leader>oo", ":ObsidianOpen<CR>", { desc = 'Open current Obsidian md note' }),

	vim.keymap.set("n", "<leader>ow", function()
		vim.ui.select({ "mico", "tectonic" }, {
				prompt = 'Change Obsidian workspace',
				format_item = function(item)
					return "Workspace: " .. item
				end,
			},
			function(choice)
				vim.cmd(":ObsidianWorkspace " .. choice)
			end
		)
	end, { desc = 'Change current Obsidian workspace' }),

	-- Get user input for name of new note
	vim.keymap.set("n", "<leader>on", function()
		vim.ui.input({ prompt = 'New Obsidian note' }, function(input)
			if input == '' then
				print("No input provided")
			elseif input then
				vim.cmd(":ObsidianNew " .. input)
			else
				print("Input cancelled")
			end
		end)
	end, { desc = 'Create new Obsidian md note' }),

	-- Get user input to rename current note
	vim.keymap.set("n", "<leader>orn", function()
		vim.ui.input({ prompt = 'Rename Obsidian note' }, function(input)
			if input == '' then
				print("No input provided")
			elseif input then
				vim.cmd(":ObsidianRename " .. input)
			else
				print("Input cancelled")
			end
		end)
	end, { desc = 'Rename an Obsidian md note' }),
}
