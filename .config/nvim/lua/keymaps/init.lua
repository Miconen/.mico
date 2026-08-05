-- keymaps/init.lua
-- Loads all keymap modules. Order matters only for which-key group labels
-- being registered before the individual binds within them.

require("keymaps.editor")
require("keymaps.search")
require("keymaps.git")
require("keymaps.lsp")
require("keymaps.ui")
