-- keymaps/test.lua
-- Group label only — binds live on the neotest lazy spec so the plugin loads on use.
local wk = require("which-key")
local icons = require("keymaps.icons")

wk.add({
	{ "<leader>t", group = icons.Test .. " Test" },
})
