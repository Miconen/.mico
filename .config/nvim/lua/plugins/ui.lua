-- plugins/ui.lua

return {
	{
		"scottmckendry/cyberdream.nvim",
		lazy = false,
		priority = 1000,
		opts = {
			transparent = true,
		},
		config = function(_, opts)
			require("cyberdream").setup(opts)
			vim.cmd.colorscheme("cyberdream")
		end,
	},

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			preset = "helix",
			win = {
				col = 0,
				width = { min = 30, max = 40 },
				height = { min = 15, max = 60 },
			},
			layout = {
				width = { min = 20, max = 40 },
				spacing = 3,
				align = "left",
			},
			icons = {
				rules = false,
			},
		},
	},

	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			bigfile = { enabled = true },
			notifier = { enabled = true, timeout = 3000 },
			quickfile = { enabled = true },
			toggle = { which_key = true },
			rename = { enabled = true },
			gitbrowse = { enabled = true },
			lazygit = { enabled = true },
			scratch = { enabled = true },
			dim = { enabled = true },
			statuscolumn = { enabled = true },
			picker = {
				enabled = true,
				ui_select = true,
			},
			-- Unused in this config (no keymaps / no call sites)
			words = { enabled = false },
			zen = { enabled = false },
			terminal = { enabled = false },
			dashboard = { enabled = false },
		},
	},

	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		opts = {
			indent = { char = "│" },
			scope = { enabled = true },
		},
	},

	{
		"folke/todo-comments.nvim",
		event = "VimEnter",
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = { signs = false },
	},
}
