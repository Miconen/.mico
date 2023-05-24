require("oil").setup({})

vim.keymap.set("n", "-", require("oil").open_float, { desc = "Open parent directory with oil.nvim" })
