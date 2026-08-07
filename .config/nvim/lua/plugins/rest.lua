-- plugins/rest.lua
--
-- HTTP client driven from .http files, so requests live in the repo next to the
-- code instead of in a GUI app's private database.
--
-- External requirements, all already declared in home/common.nix: curl (kulala
-- downloads its kulala-core backend with it), git, and tree-sitter-cli, which
-- builds the bundled kulala-http grammar. The parser is kulala's own, so it is
-- deliberately not added to the list in plugins/treesitter.lua.
--
-- Needs Neovim >= 0.12; this config already targets 0.13.
--
-- kulala sets its own buffer-local keymaps in .http files by default
-- (kulala_keymaps = true, with an empty prefix), so `e` selects the environment,
-- `s`/<CR> send, `a` sends all, `n`/`p` jump between requests and `q` closes the
-- result window. The <C-*> binds below therefore duplicate some of those; they
-- are kept because they are what the nvim-2025 develop config used.
return {
	{
		"mistweaverco/kulala.nvim",
		ft = { "http" },
		keys = {
			{
				"<C-y>",
				function()
					require("kulala").run()
				end,
				ft = "http",
				desc = " Run request",
			},
			{
				"<C-n>",
				function()
					require("kulala").jump_next()
				end,
				ft = "http",
				desc = "Next request",
			},
			{
				"<C-p>",
				function()
					require("kulala").jump_prev()
				end,
				ft = "http",
				desc = "Prev request",
			},
		},
		opts = {
			-- Which block of http-client.env.json supplies {{variables}}.
			--
			-- Resolution order in kulala is vim.g.kulala_selected_env, then the
			-- env picked at runtime (persisted in kulala's own settings file),
			-- then this, then the literal string "default".
			--
			-- Note this is NOT read from a .kulala.json in the project - kulala has
			-- no such file, so a default_env set there is silently ignored and every
			-- {{var}} stays unexpanded. Declaring it here keeps it in git instead of
			-- in kulala's stateful settings file.
			--
			-- Projects whose env file has no "dev" block still need `e` in the
			-- buffer to pick one.
			default_env = "dev",

			contenttypes = {
				["application/problem%+json"] = "application/json",
			},
		},
	},
}
