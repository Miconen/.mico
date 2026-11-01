-- nvim-treesitter `main` branch (the rewrite): no lazy-loading, no configs API,
-- and highlighting must be started per filetype. Needs tree-sitter-cli >= 0.26.1.

local parsers = {
	-- Bundled with Neovim, listed to keep queries in sync with this plugin.
	"bash",
	"c",
	"diff",
	"html",
	"lua",
	"luadoc",
	"markdown",
	"markdown_inline",
	"query",
	"vim",
	"vimdoc",
	"go",
	"gomod",
	"gowork",
	"gosum",
	"typescript",
	"javascript",
	"tsx",
	"python",
	"json",
	"yaml",
	"toml",
	"css",
	"scss",
	"sql",
	"dockerfile",
	"gitcommit",
	"gitignore",
}

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter").setup()

			require("nvim-treesitter").install(parsers)

			vim.treesitter.language.register("json", "jsonc")

			-- Treesitter indent and folds are deliberately not enabled.
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true }),
				callback = function(event)
					local lang = vim.treesitter.language.get_lang(event.match) or event.match

					-- get_lang() can't tell whether a parser exists; start() errors without one.
					local ok, has_parser = pcall(vim.treesitter.language.add, lang)
					if not (ok and has_parser) then
						return
					end

					vim.treesitter.start(event.buf, lang)
				end,
			})
		end,
	},
}
