return {
	-- Detect tabstop and shiftwidth automatically
	{
		'tpope/vim-sleuth',
		event = "VeryLazy",
	},

	-- Git related plugins
	{
		'tpope/vim-fugitive',
		event = "VeryLazy",
	},
	{
		'tpope/vim-rhubarb',
		event = "VeryLazy",
	},

	-- Database related plugins
	{
		"tpope/vim-dadbod",
		event = "VeryLazy",
	},
	{
		"kristijanhusak/vim-dadbod-completion",
		event = "VeryLazy",
	},
	{
		"kristijanhusak/vim-dadbod-ui",
		event = "VeryLazy",
		config = function()
			vim.keymap.set("n", "<leader>db", ":tab DBUI<CR>", { desc = "Open a new [D]ata[B]ase tab" })
		end
	},

	{
		"onsails/lspkind.nvim",
		event = "VeryLazy",
	},

	-- NOTE: This is where your plugins related to LSP can be installed.
	--  The configuration is done below. Search for lspconfig to find it below.
	{
		-- LSP Configuration & Plugins
		'neovim/nvim-lspconfig',
		event = "VeryLazy",
		dependencies = {
			-- Automatically install LSPs to stdpath for neovim
			'williamboman/mason.nvim',
			'williamboman/mason-lspconfig.nvim',

			-- Useful status updates for LSP
			-- NOTE: `opts = {}` is the same as calling `require('fidget').setup({})`
			{ 'j-hui/fidget.nvim', opts = { notification = { window = { winblend = 0 } } } },

			-- Additional lua configuration, makes nvim stuff amazing!
			'folke/neodev.nvim',
		},
	},

	{
		-- Autocompletion
		'hrsh7th/nvim-cmp',
		event = "VeryLazy",
		dependencies = {
			-- Snippet Engine & its associated nvim-cmp source
			'L3MON4D3/LuaSnip',
			'saadparwaiz1/cmp_luasnip',

			-- Adds LSP completion capabilities
			'hrsh7th/cmp-nvim-lsp',
			'hrsh7th/cmp-path',

			-- Adds a number of user-friendly snippets
			'rafamadriz/friendly-snippets',
		},
	},

	-- Useful plugin to show you pending keybinds.
	{
		'folke/which-key.nvim',
		event = "VeryLazy",
		opts = {}
	},
	{
		-- Adds git related signs to the gutter, as well as utilities for managing changes
		'lewis6991/gitsigns.nvim',
		event = "VeryLazy",
		opts = {
			-- See `:help gitsigns.txt`
			signs = {
				add = { text = '+' },
				change = { text = '~' },
				delete = { text = '_' },
				topdelete = { text = '‾' },
				changedelete = { text = '~' },
			},
			on_attach = function(bufnr)
				local gs = package.loaded.gitsigns

				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation
				map({ 'n', 'v' }, ']c', function()
					if vim.wo.diff then
						return ']c'
					end
					vim.schedule(function()
						gs.next_hunk()
					end)
					return '<Ignore>'
				end, { expr = true, desc = 'Jump to next hunk' })

				map({ 'n', 'v' }, '[c', function()
					if vim.wo.diff then
						return '[c'
					end
					vim.schedule(function()
						gs.prev_hunk()
					end)
					return '<Ignore>'
				end, { expr = true, desc = 'Jump to previous hunk' })

				-- Actions
				-- visual mode
				map('v', '<leader>hs', function()
					gs.stage_hunk { vim.fn.line '.', vim.fn.line 'v' }
				end, { desc = 'stage git hunk' })
				map('v', '<leader>hr', function()
					gs.reset_hunk { vim.fn.line '.', vim.fn.line 'v' }
				end, { desc = 'reset git hunk' })
				-- normal mode
				map('n', '<leader>hs', gs.stage_hunk, { desc = 'git stage hunk' })
				map('n', '<leader>hr', gs.reset_hunk, { desc = 'git reset hunk' })
				map('n', '<leader>hS', gs.stage_buffer, { desc = 'git Stage buffer' })
				map('n', '<leader>hu', gs.undo_stage_hunk, { desc = 'undo stage hunk' })
				map('n', '<leader>hR', gs.reset_buffer, { desc = 'git Reset buffer' })
				map('n', '<leader>hp', gs.preview_hunk, { desc = 'preview git hunk' })
				map('n', '<leader>hb', function()
					gs.blame_line { full = false }
				end, { desc = 'git blame line' })
				map('n', '<leader>hd', gs.diffthis, { desc = 'git diff against index' })
				map('n', '<leader>hD', function()
					gs.diffthis '~'
				end, { desc = 'git diff against last commit' })

				-- Toggles
				map('n', '<leader>tb', gs.toggle_current_line_blame, { desc = 'toggle git blame line' })
				map('n', '<leader>td', gs.toggle_deleted, { desc = 'toggle git show deleted' })

				-- Text object
				map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'select git hunk' })
			end,
		},
	},

	{
		-- Add indentation guides even on blank lines
		'lukas-reineke/indent-blankline.nvim',
		event = "VeryLazy",
		-- Enable `lukas-reineke/indent-blankline.nvim`
		-- See `:help ibl`
		main = 'ibl',
		opts = {},
	},

	-- "gc" to comment visual regions/lines
	{
		'numToStr/Comment.nvim',
		event = "VeryLazy",
		opts = {}
	},

	-- Fuzzy Finder (files, lsp, etc)
	{
		'nvim-telescope/telescope.nvim',
		event = "VeryLazy",
		branch = '0.1.x',
		dependencies = {
			'nvim-lua/plenary.nvim',
			-- Fuzzy Finder Algorithm which requires local dependencies to be built.
			-- Only load if `make` is available. Make sure you have the system
			-- requirements installed.
			{
				'nvim-telescope/telescope-fzf-native.nvim',
				-- NOTE: If you are having trouble with this installation,
				--       refer to the README for telescope-fzf-native for more instructions.
				build = 'make',
				cond = function()
					return vim.fn.executable 'make' == 1
				end,
			},
		},
	},

	{
		-- Highlight, edit, and navigate code
		'nvim-treesitter/nvim-treesitter',
		event = "VeryLazy",
		dependencies = {
			'nvim-treesitter/nvim-treesitter-textobjects',
		},
		build = ':TSUpdate',
	},

	{ import = 'mico.plugins' },

	-- undotree
	{
		"mbbill/undotree",
		event = "VeryLazy",
	},

	-- Trouble
	{
		"folke/trouble.nvim",
		event = "VeryLazy",
		dependencies = { "kyazdani42/nvim-web-devicons" },
	},

	-- refactoring.nvim
	{
		"ThePrimeagen/refactoring.nvim",
		event = "VeryLazy",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
		},
		config = function()
			require("refactoring").setup({})
		end,
	},

	-- Copilot
	{
		"github/copilot.vim",
		event = "VeryLazy",
	},

	-- Visual
	{
		"lukas-reineke/indent-blankline.nvim",
		event = "VeryLazy",
	},

	-- Misc
	{
		"kylechui/nvim-surround",
		event = "VeryLazy",
		config = function()
			require("nvim-surround").setup({})
		end,
	},

	{
		"christoomey/vim-tmux-navigator",
		event = "VeryLazy",
	},

	{
		"gelguy/wilder.nvim",
		event = "VeryLazy",
		build = function()
			pcall(vim.cmd, "UpdateRemotePlugins")
		end,
		config = function()
			local wilder = require("wilder")
			wilder.setup({ modes = { ":", "/", "?" } })
			wilder.set_option(
				"renderer",
				wilder.popupmenu_renderer({
					highlighter = wilder.basic_highlighter(),
					left = { " ", wilder.popupmenu_devicons() },
					right = { " ", wilder.popupmenu_scrollbar() },
				})
			)
		end,
	},
}
