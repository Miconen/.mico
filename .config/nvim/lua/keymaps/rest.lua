-- keymaps/rest.lua
-- Group label only — binds come from kulala's own global_keymaps, enabled in the
-- lazy spec at plugins/rest.lua.
local wk = require("which-key")
local icons = require("keymaps.icons")

wk.add({
	{ "<leader>R", group = icons.Rest .. " Rest" },
})
