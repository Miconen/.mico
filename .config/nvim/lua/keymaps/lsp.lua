-- Group label only; buffer-local binds are set on LspAttach in plugins/lsp.lua.
local wk = require("which-key")
local icons = require("keymaps.icons")

wk.add({
	{ "<leader>l", group = icons.ActiveLSP .. " LSP" },
})
