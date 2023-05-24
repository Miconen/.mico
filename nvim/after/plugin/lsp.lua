local lsp = require("lsp-zero").preset("recommended")

local cmp = require("cmp")
local cmp_action = require("lsp-zero").cmp_action()
local cmp_select = require("lsp-zero").cmp_select()

cmp.setup({
	mapping = {
		["<TAB>"] = cmp_action.luasnip_supertab(cmp_select),
		["<S-TAB>"] = cmp_action.luasnip_shift_supertab(cmp_select),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
		["<C-Space>"] = cmp.mapping.complete(),
	},
})

lsp.on_attach(function(_, bufnr)
	local opts =
		{ buffer = bufnr, remap = false }, vim.keymap.set("n", "K", function()
			vim.lsp.buf.hover()
		end, opts)
	vim.keymap.set("n", "<leader>.", function()
		vim.lsp.buf.code_action()
	end, opts)
	vim.keymap.set("n", "gd", function()
		vim.lsp.buf.definition()
	end, opts)
	vim.keymap.set("n", "gi", function()
		vim.lsp.buf.implementation()
	end, opts)
	vim.keymap.set("n", "<F2>", function()
		vim.lsp.buf.rename()
	end, opts)

	-- Diagnostics
	vim.keymap.set("n", "ge", function()
		vim.diagnostic.goto_next()
	end, opts)
	vim.keymap.set("n", "gE", function()
		vim.diagnostic.goto_prev()
	end, opts)

	-- Format buffer
	vim.keymap.set({ "n", "x" }, "<leader>l", function()
		vim.lsp.buf.format({ async = false, timeout_ms = 3000 })
	end, opts)
end)

lsp.setup()
