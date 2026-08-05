-- plugins/statusline.lua
-- nvim-navic: provides LSP symbol context to the winbar

return {
	{
		"SmiteshP/nvim-navic",
		lazy = true,
		opts = {
			-- auto_attach: no changes to lsp.lua needed
			lsp = { auto_attach = true },
			highlight = true, -- per-kind colors (NavicIconsFunction, NavicIconsClass, etc.)
			separator = " › ", -- matches WinBarSep style
			depth_limit = 5,
			icons = {
				File = "󰈙 ",
				Module = " ",
				Namespace = "󰌗 ",
				Package = " ",
				Class = "󰌗 ",
				Method = "󰆧 ",
				Property = " ",
				Field = " ",
				Constructor = " ",
				Enum = "󰕘 ",
				Interface = "󰕘 ",
				Function = "󰊕 ",
				Variable = "󰆧 ",
				Constant = "󰏿 ",
				String = " ",
				Number = "󰎠 ",
				Boolean = "◩ ",
				Array = "󰅪 ",
				Object = "󰅩 ",
				Key = "󰌋 ",
				Null = "󰟢 ",
				EnumMember = " ",
				Struct = "󰌗 ",
				Event = " ",
				Operator = "󰆕 ",
				TypeParameter = "󰊄 ",
			},
		},
	},
}
