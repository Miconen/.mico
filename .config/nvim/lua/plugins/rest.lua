-- kulala bundles its own http parser; don't add it to plugins/treesitter.lua.
return {
	{
		"mistweaverco/kulala.nvim",
		ft = { "http" },
		keys = {
			-- kulala's non-filetype-scoped global keymaps; no rhs, so lazy loads
			-- the plugin and replays the key onto kulala's own mapping.
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
			global_keymaps = true,

			-- Must be set here: kulala ignores default_env in a project .kulala.json.
			default_env = "dev",

			contenttypes = {
				["application/problem%+json"] = "application/json",
			},
		},
	},
}
