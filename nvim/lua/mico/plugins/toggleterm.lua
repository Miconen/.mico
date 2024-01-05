return {
  "akinsho/toggleterm.nvim",
  event = "VeryLazy",

  config = function()
    local toggleterm = require("toggleterm")

    toggleterm.setup({
      size = 13,
      open_mapping = [[<leader>tt]],
      insert_mappings = false,
      shade_filetypes = {},
      shade_terminal = true,
      shading_factor = 1,
      start_in_insert = true,
      persist_size = true,
      direction = "float",
      autochdir = true,
    })
  end,
}
