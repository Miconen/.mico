-- plugins/db.lua (new file)
return {
	{
		"tpope/vim-dadbod",
		cmd = { "DB", "DBUI" },
		dependencies = {
			{
				"kristijanhusak/vim-dadbod-ui",
				keys = {
					{ "<leader>D", "<cmd>DBUIToggle<cr>", desc = "Toggle DB UI" },
				},
				init = function()
					vim.g.db_ui_use_nerd_fonts = 1
					vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
					vim.g.db_ui_execute_on_save = 0 -- don't auto-run on save
				end,
			},
			-- Completion for SQL (hook into blink.cmp)
			{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" } },
		},
	},
}
