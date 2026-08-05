-- plugins/treesitter.lua
--
-- This targets the nvim-treesitter REWRITE (the `main` branch), which upstream
-- describes as "a full, incompatible rewrite: treat this as a different plugin".
-- Nothing here carries over from the old `nvim-treesitter.configs` API:
--
--   * no lazy-loading - upstream states the plugin does not support it, so the
--     event/cmd gating this spec used to have is gone and it loads at startup
--   * no `opts`/`main`; parsers are installed by calling install()
--   * highlighting is NOT automatic. It is Neovim's, enabled per filetype with
--     vim.treesitter.start()
--   * :TSUpdate is mandatory after every plugin update, because parser versions
--     are pinned in the plugin's parser.lua
--
-- External requirements, which is why home/common.nix declares tree-sitter:
-- tree-sitter-cli >= 0.26.1, a C compiler (pacman gcc), curl and tar.

local parsers = {
	-- Neovim ships c, lua, vim, vimdoc, query and markdown parsers itself, but
	-- listing them keeps the queries in sync with this plugin's versions.
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
	-- Languages actually in use
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

			-- Asynchronous, and a no-op for parsers already present.
			require("nvim-treesitter").install(parsers)

			-- jsonc is not a separate upstream parser; reuse json (comments are tolerated by queries).
			vim.treesitter.language.register("json", "jsonc")

			-- Highlighting comes from Neovim, not this plugin.
			--
			-- Treesitter indentation is deliberately not enabled: upstream still marks
			-- it experimental, and vim-sleuth plus smartindent already cover this.
			-- Folds are likewise left alone - foldmethod was "manual" before this
			-- rewrite, so enabling treesitter folds here would be new behaviour rather
			-- than a migration.
			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("treesitter_highlight", { clear = true }),
				callback = function(event)
					local lang = vim.treesitter.language.get_lang(event.match) or event.match

					-- get_lang() falls back to returning the filetype itself, so it cannot
					-- tell us whether a parser exists. language.add() can: it returns true
					-- when the parser loads and nil when it does not. Without this gate,
					-- treesitter.start() raises "Parser could not be created" on every
					-- filetype lacking a parser.
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
