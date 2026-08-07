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
-- Two separate keymap sets exist in kulala, which are easy to confuse:
--
--   * kulala_keymaps (on by default, empty prefix) binds H/B/A/V, <c-h>/<c-l>
--     and friends inside kulala's own result window - NOT in .http buffers.
--   * global_keymaps (off by default) is the request actions: send, replay,
--     inspect, select environment, jump between requests. Enabled below under
--     <leader>R, the group label being in keymaps/rest.lua.
--
-- Most of the global set is filetype-scoped to http/rest by kulala itself, so
-- those appear only in .http buffers even though they are called "global".
return {
	{
		"mistweaverco/kulala.nvim",
		ft = { "http" },
		keys = {
			-- kulala creates its global_keymaps when it loads, and this spec only
			-- loads on the http filetype. These five are the ones kulala does not
			-- filetype-scope, so without a trigger they would not exist until an
			-- .http buffer had been opened. No rhs: lazy loads the plugin and then
			-- replays the key onto kulala's own mapping.
			{ "<leader>Rb", desc = "Open scratchpad" },
			{ "<leader>Ro", desc = "Open kulala" },
			{ "<leader>Rs", desc = "Send request" },
			{ "<leader>Ra", desc = "Send all requests" },
			{ "<leader>Rr", desc = "Replay last request" },

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
			-- Request actions under <leader>R: Rs send, Ra send all, Rr replay,
			-- Re select environment, Ri inspect, Rb scratchpad, Ro open, Rf find.
			global_keymaps = true,

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
