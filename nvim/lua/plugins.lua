vim.cmd [[packadd packer.nvim]]

return require('packer').startup(function()

	use 'wbthomason/packer.nvim'

	use {
  		"folke/which-key.nvim",
  		config = function()
    		require("which-key").setup {} end
	}

	use { "morhetz/gruvbox" }

	-- Plugins for Kitty terminal
	use { "fladson/vim-kitty" }
	use { "knubie/vim-kitty-navigator", run="cp ./*.py ~/.config/kitty/" }

end)
