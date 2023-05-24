-- lazy.nvim
require("mico.lazy")

-- Basic vim setup
require("mico.settings")
require("mico.remap")

-- Imports of vim plugins
local plugins = require("mico.plugins")
require("lazy").setup(plugins)
