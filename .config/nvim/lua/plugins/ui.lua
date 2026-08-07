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

	-- In-buffer markdown rendering: headings, tables, code blocks and callouts
	-- are drawn with extmarks, so the file on disk is untouched and it stays
	-- editable. No browser preview and no node/yarn build step, which keeps this
	-- inside what nix already provides.
	--
	-- Needs the markdown and markdown_inline parsers (both in
	-- plugins/treesitter.lua) and an icon provider - mini.icons, which comes
	-- from the mini.nvim spec in plugins/editor.lua.
	--
	-- Defaults are left alone: the plugin raises conceallevel per window itself,
	-- so it does not need the global <leader>uc conceal toggle.
	{
		"MeanderingProgrammer/render-markdown.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.nvim" },
		ft = { "markdown" },
		opts = {},
	},

	-- Aligned columns for CSV/TSV, with field text objects and Excel-like
	-- movement. Opt-in per buffer via :CsvViewToggle rather than on every
	-- comma-separated file.
	{
		"hat0uma/csvview.nvim",
		cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
		opts = {
			parser = { comments = { "#", "//" } },
			keymaps = {
				-- Field text objects: `if` inner, `af` outer.
				textobject_field_inner = { "if", mode = { "o", "x" } },
				textobject_field_outer = { "af", mode = { "o", "x" } },
				-- <Tab>/<S-Tab> move between fields, <Enter>/<S-Enter> between
				-- rows. <S-Tab> and <S-Enter> need CSI-u mode in the terminal.
				jump_next_field_end = { "<Tab>", mode = { "n", "v" } },
				jump_prev_field_end = { "<S-Tab>", mode = { "n", "v" } },
				jump_next_row = { "<Enter>", mode = { "n", "v" } },
				jump_prev_row = { "<S-Enter>", mode = { "n", "v" } },
			},
		},
	},
}
