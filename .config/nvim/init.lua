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

-- Leader must be set before lazy loads plugins.
vim.g.mapleader = " "
vim.g.maplocalleader = ","

require("options")
require("autocmds")

require("lazy").setup("plugins", {
	change_detection = { notify = false },
	rocks = { enabled = false },
})

require("winbar").setup()

require("statusline").setup()

-- After lazy: keymaps use Snacks and which-key.
require("keymaps")
