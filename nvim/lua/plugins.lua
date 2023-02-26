require("packer").startup(function()
    use "wbthomason/packer.nvim"

    -- LSP
    use {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "neovim/nvim-lspconfig",
    }

    -- nvim-cmp
    use {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/nvim-cmp",
    }
    use "onsails/lspkind.nvim"

    -- LuaSnip
    use({
        "L3MON4D3/LuaSnip",
        -- follow latest release.
        tag = "v<CurrentMajor>.*",
        -- install jsregexp (optional!:).
        run = "make install_jsregexp"
    })
    use 'saadparwaiz1/cmp_luasnip'

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

    -- Misc
    use 'rcarriga/nvim-notify'
    use "tpope/vim-commentary"
    use "JoosepAlviste/nvim-ts-context-commentstring"
    use "lukas-reineke/indent-blankline.nvim"
    use "lewis6991/gitsigns.nvim"
    use "petertriho/nvim-scrollbar"
    use {
        "nvim-lualine/lualine.nvim",
        requires = { "kyazdani42/nvim-web-devicons", opt = true }
    }
    use "christoomey/vim-tmux-navigator"
    use "ur4ltz/surround.nvim"
    use {
        "windwp/nvim-autopairs",
        config = function() require("nvim-autopairs").setup {} end
    }
    use "kylechui/nvim-surround"
end)
