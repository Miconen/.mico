-- Group label only; binds live on the lazy spec so the plugin loads on use.
local wk = require("which-key")
local icons = require("keymaps.icons")

wk.add({
	{ "<leader>d", group = icons.Debugger .. " Debug" },
})
