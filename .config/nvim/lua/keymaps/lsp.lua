-- keymaps/lsp.lua
-- Group label only — buffer-local LSP binds live in plugins/lsp.lua (LspAttach).

local wk = require("which-key")
local icons = require("keymaps.icons")

wk.add({
	{ "<leader>l", group = icons.ActiveLSP .. " LSP" },
})
