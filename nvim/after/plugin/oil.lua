require("oil").setup({})

-- Open oil in a floating window
vim.keymap.set("n", "-", require("oil").open_float, { desc = "Open parent directory with oil.nvim" })

-- Add <Esc> as one of the exit keys to oil
vim.keymap.set("n", "<Esc>", function()
  if vim.fn.win_gettype(vim.fn.winnr()) == "popup" then
    require("oil").close()
  end
end, { desc = "Close oli.nvim filetree buffer" })
