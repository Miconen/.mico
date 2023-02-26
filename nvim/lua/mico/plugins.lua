require("packer").startup(function()
    use "wbthomason/packer.nvim"

    -- LSP
    use {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v1.x',
        requires = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' }, -- Required
            { 'williamboman/mason.nvim' }, -- Optional
            { 'williamboman/mason-lspconfig.nvim' }, -- Optional

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' }, -- Required
            { 'hrsh7th/cmp-nvim-lsp' }, -- Required
            { 'hrsh7th/cmp-buffer' }, -- Optional
            { 'hrsh7th/cmp-path' }, -- Optional
            { 'saadparwaiz1/cmp_luasnip' }, -- Optional
            { 'hrsh7th/cmp-nvim-lua' }, -- Optional

            -- Snippets
            { 'L3MON4D3/LuaSnip' }, -- Required
            { 'rafamadriz/friendly-snippets' }, -- Optional
        }
    }

    -- Theme
    use "folke/tokyonight.nvim"

    -- Treesitter
    use { "nvim-treesitter/nvim-treesitter", { run = ':TSUpdate' } }
    use "nvim-treesitter/nvim-treesitter-context"

    -- Telescope
    use {
        "nvim-telescope/telescope.nvim",
        requires = { { "nvim-lua/plenary.nvim" } }
    }
    use "nvim-telescope/telescope-file-browser.nvim"

    -- nvim-tree
    use {
        'nvim-tree/nvim-tree.lua',
        requires = {
            'nvim-tree/nvim-web-devicons', -- optional, for file icons
        },
        tag = 'nightly' -- optional, updated every week. (see issue #1193)
    }

    -- Visual
    use "lukas-reineke/indent-blankline.nvim"
    use "petertriho/nvim-scrollbar"
    use "lewis6991/gitsigns.nvim"
    use {
        "nvim-lualine/lualine.nvim",
        requires = { "kyazdani42/nvim-web-devicons", opt = true },
        config = function() require("lualine").setup {} end
    }

    -- Misc
    use 'rcarriga/nvim-notify'
    use "JoosepAlviste/nvim-ts-context-commentstring"
    use "kylechui/nvim-surround"
    use "christoomey/vim-tmux-navigator"
end)
