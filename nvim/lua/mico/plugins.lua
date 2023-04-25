return {
    -- LSP
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v2.x',
        dependencies = {
          -- LSP Support
          {'neovim/nvim-lspconfig'},             -- Required
          {                                      -- Optional
            'williamboman/mason.nvim',
            build = function()
              pcall(vim.cmd, 'MasonUpdate')
            end,
          },
          {'williamboman/mason-lspconfig.nvim'}, -- Optional

          -- Autocompletion
          {'hrsh7th/nvim-cmp'},     -- Required
          {'hrsh7th/cmp-nvim-lsp'}, -- Required
          {'L3MON4D3/LuaSnip'},     -- Required
        }
    },

    -- Theme
    "folke/tokyonight.nvim",

    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        -- { build = "TSUpdate" }
    },
    "nvim-treesitter/nvim-treesitter-context",

    -- Telescope
    { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    "nvim-telescope/telescope-file-browser.nvim",

    -- nvim-tree
    { 'nvim-tree/nvim-tree.lua', dependencies = { "kyazdani42/nvim-web-devicons" } },

    -- Visual
    "lukas-reineke/indent-blankline.nvim",
    "petertriho/nvim-scrollbar",
    "lewis6991/gitsigns.nvim",
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "kyazdani42/nvim-web-devicons" },
        config = function() require("lualine").setup() end
    },

    -- Misc
    "JoosepAlviste/nvim-ts-context-commentstring",
    "kylechui/nvim-surround",
    "christoomey/vim-tmux-navigator",
    { "windwp/nvim-autopairs", config = function() require("nvim-autopairs").setup() end },
    { "terrortylor/nvim-comment", config = function() require("nvim_comment").setup() end },
    'gelguy/wilder.nvim',
}
