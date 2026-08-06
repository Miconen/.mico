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

	-- Project-wide find and replace in a buffer. Driven by ripgrep, which is
	-- already declared in home/common.nix (grug-far wants rg >= 14).
	--
	-- Binds live here rather than in keymaps/search.lua so the plugin loads on
	-- first use; the <leader>s group label is registered there.
	--
	-- <leader>sr is taken by Snacks recent files, hence sR.
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
					-- auto-detect: a linewise selection confines the replace to that
					-- range, a charwise one pre-fills the search input with it.
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
}
