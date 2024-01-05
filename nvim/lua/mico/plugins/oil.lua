return {
  "stevearc/oil.nvim",
  event = "VeryLazy",
  opts = {},
  -- Optional dependencies
  dependencies = { "kyazdani42/nvim-web-devicons" },
  config = function()
    require("oil").setup({
      keymaps = {
        ["<Esc>"] = "actions.close",
        ["q"] = "actions.close"
      },
      buf_options = {
        buflisted = false,
        bufhidden = "delete",
      },
      float = {
        -- Padding around the floating window
        padding = 2,
        max_width = 60,
        max_height = 16,
        border = "rounded",
        win_options = {
          winblend = 0,
        },
      },
    })

    -- Open oil in a floating window
    vim.keymap.set("n", "-", require("oil").open_float, { desc = "Open parent directory with oil.nvim" })
  end,
}
