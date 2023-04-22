-- disable netrw at the very start of your init.lua (strongly advised)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

require("nvim-tree").setup {
    view = {
        mappings = {
            custom_only = false,
            list = {
                -- user mappings go here
            },
        },
    },
    renderer = {
        root_folder_label = false,
        group_empty = true,
        highlight_git = true,
        full_name = false,
        icons = {
            webdev_colors = true,
            git_placement = "after",
            modified_placement = "after",
            padding = " ",
            symlink_arrow = " ➛ ",
            glyphs = {
                default = "",
                symlink = "",
                bookmark = "",
                modified = "●",
                folder = {
                    arrow_closed = "",
                    arrow_open = "",
                    default = "",
                    open = "",
                    empty = "",
                    empty_open = "",
                    symlink = "",
                    symlink_open = "",
                },
                git = {
                    unstaged = "",
                    staged = "✓",
                    unmerged = "",
                    renamed = "➜",
                    untracked = "+",
                    deleted = "",
                    ignored = "◌",
                },
            },
        },
    },
    diagnostics = {
        enable = true,
        show_on_dirs = true,
        show_on_open_dirs = true,
        debounce_delay = 50,
        severity = {
            min = vim.diagnostic.severity.HINT,
            max = vim.diagnostic.severity.ERROR,
        },
        icons = {
            hint = "",
            info = "",
            warning = "",
            error = "",
        },
    },
    filters = {
        dotfiles = false,
        git_clean = false,
        no_buffer = false,
        custom = {},
        exclude = {},
    },
    git = {
        enable = true,
        ignore = true,
        show_on_dirs = true,
        show_on_open_dirs = true,
        timeout = 400,
    },
    modified = {
        enable = false,
        show_on_dirs = true,
        show_on_open_dirs = true,
    },
    actions = {
        open_file = {
            quit_on_open = true,
            resize_window = true,
            window_picker = {
                enable = true,
                picker = "default",
                chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
                exclude = {
                    filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" },
                    buftype = { "nofile", "terminal", "help" },
                },
            },
        },
    },
}

vim.keymap.set("n", "<leader>,", ":NvimTreeToggle<CR>", {})
