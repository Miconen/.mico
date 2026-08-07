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
			contenttypes = {
				["application/problem%+json"] = "application/json",
			},
		},
	},
}
