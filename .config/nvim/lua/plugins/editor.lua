-- plugins/editor.lua

return {
	-- Detect tabstop/shiftwidth automatically
	"tpope/vim-sleuth",

	-- Mini.nvim collection
	{
		"echasnovski/mini.nvim",
		version = false,
		config = function()
			-- Better text objects: va), yinq, ci'
			require("mini.ai").setup({ n_lines = 500 })

			-- Surround: saiw), sd', sr)'
			require("mini.surround").setup({})

			-- Icons (used by statusline and other mini modules)
			require("mini.icons").setup({})

			-- File explorer
			require("mini.files").setup({
				options = {
					use_as_default_explorer = true,
				},
			})

			-- Git diff signs in the gutter + overlay
			require("mini.diff").setup({
				view = {
					style = "sign",
					signs = { add = "▎", change = "▎", delete = "" },
				},
			})

			-- Git blame / log integration
			require("mini.git").setup({})
		end,
	},

	-- Autopairs
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
		-- blink.cmp integration is handled in plugins/lsp.lua
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
}
