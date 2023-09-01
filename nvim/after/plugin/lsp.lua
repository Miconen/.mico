local lsp = require("lsp-zero").preset("recommended")

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

local cmp = require("cmp")
local compare = require("cmp.config.compare")
local cmp_action = require("lsp-zero").cmp_action()

local autocomplete_group = vim.api.nvim_create_augroup("vimrc_autocompletion", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "sql", "mysql", "plsql" },
	callback = function()
		cmp.setup.buffer({ sources = { { name = "vim-dadbod-completion" } } })
	end,
	group = autocomplete_group,
})

cmp.setup({
	mapping = {
		["<TAB>"] = cmp_action.luasnip_supertab(cmp_select),
		["<S-TAB>"] = cmp_action.luasnip_shift_supertab(cmp_select),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
		["<C-Space>"] = cmp.mapping.complete(),
	},
	formatting = {
		fields = { "kind", "abbr", "menu" },
		format = function(entry, vim_item)
			local kind = require("lspkind").cmp_format({ mode = "symbol_text", maxwidth = 50 })(entry, vim_item)
			local strings = vim.split(kind.kind, "%s", { trimempty = true })
			kind.kind = " " .. (strings[1] or "") .. " "
			kind.menu = "    (" .. (strings[2] or "") .. ")"

			return kind
		end,
	},
	sorting = {
		comparators = {
			compare.exact,
			compare.recently_used,
		},
	},
	window = {
		completion = cmp.config.window.bordered({
            border = "none",
			winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
			col_offset = -3,
			side_padding = 0,
		}),
	},
})
