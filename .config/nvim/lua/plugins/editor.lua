return {
	"tpope/vim-sleuth",

	{
		"echasnovski/mini.nvim",
		version = false,
		config = function()
			require("mini.ai").setup({ n_lines = 500 })

			require("mini.surround").setup({})

			require("mini.icons").setup({})

			require("mini.files").setup({
				options = {
					use_as_default_explorer = true,
				},
			})

			require("mini.diff").setup({
				view = {
					style = "sign",
					signs = { add = "▎", change = "▎", delete = "" },
				},
			})

			require("mini.git").setup({})
		end,
	},

	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},

	{
		"folke/flash.nvim",
		event = "VeryLazy",
		opts = {
			modes = {
				char = {
					jump_labels = true,
				},
			},
		},
		keys = {
			{
				"s",
				mode = { "n", "x", "o" },
				function()
					require("flash").jump()
				end,
				desc = "Flash jump",
			},
			{
				"S",
				mode = { "n", "x", "o" },
				function()
					require("flash").treesitter()
				end,
				desc = "Flash treesitter",
			},
		},
	},

	-- Needs ripgrep >= 14.
	{
		"MagicDuck/grug-far.nvim",
		cmd = { "GrugFar", "GrugFarWithin" },
		opts = {},
		keys = {
			{
				"<leader>sR",
				function()
					require("grug-far").open()
				end,
				desc = "Search and replace",
			},
			{
				"<leader>sR",
				mode = "x",
				function()
					require("grug-far").open({ visualSelectionUsage = "auto-detect" })
				end,
				desc = "Search and replace in selection",
			},
			{
				"<leader>sW",
				function()
					require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
				end,
				desc = "Search and replace word under cursor",
			},
		},
	},

	{
		"chrisgrieser/nvim-scissors",
		dependencies = { "folke/snacks.nvim" },
		opts = {
			snippetDir = vim.fn.stdpath("config") .. "/snippets",
		},
		keys = {
			{
				"<leader>sa",
				function()
					require("scissors").addNewSnippet()
				end,
				mode = { "n", "x" },
				desc = "Add snippet from selection / new",
			},
			{
				"<leader>se",
				function()
					require("scissors").editSnippet()
				end,
				desc = "Edit / search snippets",
			},
		},
	},
}
