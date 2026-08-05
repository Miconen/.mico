-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- Leader must be set before lazy so which-key picks it up correctly
vim.g.mapleader = " "
vim.g.maplocalleader = ","

require("options")
require("autocmds")

require("lazy").setup("plugins", {
	change_detection = { notify = false },
	rocks = { enabled = false },
})

-- Winbar breadcrumb (configured in lua/winbar.lua)
require("winbar").setup()

-- Statusline (configured in lua/statusline.lua)
require("statusline").setup()

-- Keymaps are loaded after plugins so snacks/wk are available
require("keymaps")
