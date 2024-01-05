local cmp = require 'cmp'
local compare = require 'cmp.config.compare'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

-- Setup dadbod
-- local autocomplete_group = vim.api.nvim_create_augroup("vimrc_autocompletion", { clear = true })
-- vim.api.nvim_create_autocmd("FileType", {
-- 	pattern = { "sql", "mysql", "plsql" },
-- 	callback = function()
-- 		cmp.setup.buffer({ sources = { { name = "vim-dadbod-completion" } } })
-- 	end,
-- 	group = autocomplete_group,
-- })

cmp.setup {
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	completion = {
		completeopt = 'menu,menuone,noinsert',
	},
	mapping = cmp.mapping.preset.insert {
		['<C-n>'] = cmp.mapping.select_next_item(),
		['<C-p>'] = cmp.mapping.select_prev_item(),
		['<C-d>'] = cmp.mapping.scroll_docs(-4),
		['<C-f>'] = cmp.mapping.scroll_docs(4),
		['<C-Space>'] = cmp.mapping.complete {},
		['<CR>'] = cmp.mapping.confirm {
			behavior = cmp.ConfirmBehavior.Replace,
			select = true,
		},
		['<Tab>'] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			elseif luasnip.expand_or_locally_jumpable() then
				luasnip.expand_or_jump()
			else
				fallback()
			end
		end, { 'i', 's' }),
		['<S-Tab>'] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			elseif luasnip.locally_jumpable(-1) then
				luasnip.jump(-1)
			else
				fallback()
			end
		end, { 'i', 's' }),
	},
	sources = {
		{ name = 'nvim_lsp' },
		{ name = 'luasnip' },
		{ name = 'path' },
	},
	formatting = {
		fields = { "kind", "abbr", "menu" },
		format = function(entry, vim_item)
			local kind = require("lspkind").cmp_format({ mode = "symbol_text", maxwidth = 50 })(entry, vim_item)
			local strings = vim.split(kind.kind, "%s", { trimempty = true })

			kind.kind = " " .. (strings[1] or "") .. " "
			kind.menu = "    (" .. (strings[2] or "") .. ")"

			local maxwidth = 80
			vim_item.abbr = string.sub(vim_item.abbr, 1, maxwidth)

			return vim_item
		end,
	},
	sorting = {
		priority_weight = 2,
		comparators = {
			compare.recently_used,
			compare.exact,
		},
	},
	window = {
		completion = cmp.config.window.bordered({
			border = "none",
			winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:none",
			col_offset = 0,
			side_padding = 0,
		}),
	},
}
