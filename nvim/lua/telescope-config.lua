local telescope = require("telescope")

telescope.setup {
    pickers = {
        find_files = {
              theme = "dropdown",
              previewer = false,
        }
    },
    extensions = {
        file_browser = {
              theme = "dropdown",
              previewer = false,
        }
    },
    defaults = {
        file_ignore_patterns = { "node_modules", "dist", "build", "bin", "obj" },
    }
}

require("telescope").load_extension "file_browser"

local opts = { noremap = true }
vim.api.nvim_set_keymap('n', '<C-P>', "<cmd>lua require('telescope.builtin').find_files()<CR>", opts)
vim.api.nvim_set_keymap('n', '<C-N>', ":Telescope file_browser<CR>", opts)
vim.api.nvim_set_keymap('n', '<C-F>', "<cmd>lua require('telescope.builtin').live_grep()<CR>", opts)
vim.api.nvim_set_keymap('n', '<C-B>', "<cmd>lua require('telescope.builtin').buffers()<CR>", opts)
vim.api.nvim_set_keymap('n', '<C-L>', "<cmd>lua require('telescope.builtin').oldfiles()<CR>", opts)
