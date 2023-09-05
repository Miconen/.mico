local function tabnine_build_path()
    if vim.loop.os_uname().sysname == "Windows_NT" then
        return "powershell.exe -File .\\install.ps1"
    else
        return "./install.sh"
    end
end

return {
    -- LSP
    {
        "VonHeikemen/lsp-zero.nvim",
        branch = "v2.x",
        dependencies = {
            -- LSP Support
            { "neovim/nvim-lspconfig" }, -- Required
            {
                -- Optional
                "williamboman/mason.nvim",
                build = function()
                    pcall(vim.cmd, "MasonUpdate")
                end,
            },
            { "williamboman/mason-lspconfig.nvim" }, -- Optional

            -- Autocompletion
            { "hrsh7th/nvim-cmp" },     -- Required
            { "hrsh7th/cmp-nvim-lsp" }, -- Required
            { "L3MON4D3/LuaSnip" },     -- Required
        },
    },

    -- Theme
    "folke/tokyonight.nvim",

    -- Treesitter
    {
        "nvim-treesitter/nvim-treesitter",
        build = function()
            pcall(vim.cmd, "TSUpdate")
        end,
    },
    "nvim-treesitter/nvim-treesitter-context",

    -- Telescope
    { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
    "nvim-telescope/telescope-file-browser.nvim",

    -- oil.nvim
    {
        "stevearc/oil.nvim",
        opts = {},
        -- Optional dependencies
        dependencies = { "kyazdani42/nvim-web-devicons" },
    },

    -- undotree
    "mbbill/undotree",

    -- Trouble
    {
        "folke/trouble.nvim",
        dependencies = { "kyazdani42/nvim-web-devicons" },
    },

    -- refactoring.nvim
    {
        "ThePrimeagen/refactoring.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-treesitter/nvim-treesitter",
        },
        config = function()
            require("refactoring").setup()
        end,
    },

    -- null-ls
    {
        "jay-babu/mason-null-ls.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "jose-elias-alvarez/null-ls.nvim",
        },
        config = function()
            require("null-ls")
        end,
    },

    -- Visual
    "lukas-reineke/indent-blankline.nvim",
    "petertriho/nvim-scrollbar",
    "lewis6991/gitsigns.nvim",
    "onsails/lspkind.nvim",
    {
        "nvim-lualine/lualine.nvim",
        dependencies = { "kyazdani42/nvim-web-devicons" },
        config = function()
            require("lualine").setup()
        end,
    },

    -- DB
    "tpope/vim-dadbod",
    "kristijanhusak/vim-dadbod-ui",
    "kristijanhusak/vim-dadbod-completion",

    -- Tabnine
    {
        "tzachar/cmp-tabnine",
        build = tabnine_build_path(),
        dependencies = "hrsh7th/nvim-cmp",
    },

    -- Misc
    "JoosepAlviste/nvim-ts-context-commentstring",
    {
        "kylechui/nvim-surround",
        config = function()
            require("nvim-surround").setup()
        end,
    },
    "christoomey/vim-tmux-navigator",
    {
        "windwp/nvim-autopairs",
        config = function()
            require("nvim-autopairs").setup()
        end,
    },
    {
        "terrortylor/nvim-comment",
        config = function()
            require("nvim_comment").setup()
        end,
    },
    {
        "gelguy/wilder.nvim",
        build = function()
            pcall(vim.cmd, "UpdateRemotePlugins")
        end,
    },
}
