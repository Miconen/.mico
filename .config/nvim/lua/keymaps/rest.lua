-- Group label only; binds come from kulala's global_keymaps.
local wk = require("which-key")
local icons = require("keymaps.icons")

wk.add({
	{ "<leader>R", group = icons.Rest .. " Rest" },
})
