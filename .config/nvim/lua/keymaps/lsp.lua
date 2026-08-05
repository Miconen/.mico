-- keymaps/lsp.lua
-- Group label only — individual LSP binds are set on LspAttach
-- in plugins/lsp.lua so they are buffer-local and only active
-- when an LSP client is attached.

local wk = require("which-key")

wk.add({
	{ "<leader>l", group = " LSP" },
})
