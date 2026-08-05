-- plugins/lsp.lua

-- selene: allow(unused_variable, shadowing)
-- Outer `map` is closed over by the inner LspAttach wrapper (Lua locals are not
-- in scope until after their own statement — the inner call hits this binding).
local map = vim.keymap.set
local icons = require("keymaps.icons")

return {
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "luvit-meta/library", words = { "vim%.uv" } },
				{ path = "snacks.nvim", words = { "Snacks" } },
			},
		},
	},
	{ "Bilal2453/luvit-meta", lazy = true },

	{
		"mason-org/mason.nvim",
		cmd = {
			"Mason",
			"MasonInstall",
			"MasonUninstall",
			"MasonUninstallAll",
			"MasonLog",
			"MasonUpdate",
		},
		opts = {
			ui = {
				icons = {
					package_installed = "✓",
					package_uninstalled = "✗",
					package_pending = "⟳",
				},
			},
		},
	},

	{ "mason-org/mason-lspconfig.nvim", lazy = true },
	{ "WhoIsSethDaniel/mason-tool-installer.nvim", lazy = true },

	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"saghen/blink.cmp",
		},
		config = function()
			if vim.g.have_nerd_font then
				local signs = {
					ERROR = icons.DiagnosticError,
					WARN = icons.DiagnosticWarn,
					INFO = icons.DiagnosticInfo,
					HINT = icons.DiagnosticHint,
				}
				local diagnostic_signs = {}
				for type, icon in pairs(signs) do
					diagnostic_signs[vim.diagnostic.severity[type]] = icon
				end
				vim.diagnostic.config({
					signs = { text = diagnostic_signs },
					virtual_text = true,
					underline = true,
					severity_sort = true,
					-- false: avoid redrawing diagnostics on every keystroke (costly on modest CPUs).
					update_in_insert = false,
					float = {
						focused = false,
						style = "minimal",
						border = "rounded",
						source = "always",
						header = "",
						prefix = "",
					},
				})
			end

			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp_attach_keymaps", { clear = true }),
				callback = function(event)
					local buf = event.buf
					-- selene: allow(shadowing)
					-- Wraps outer map with buffer + "LSP: " desc prefix.
					local map = function(keys, func, desc, mode)
						map(mode or "n", keys, func, { buffer = buf, desc = "LSP: " .. desc })
					end

					map("gd", function()
						Snacks.picker.lsp_definitions()
					end, "Goto definition")
					map("gr", function()
						Snacks.picker.lsp_references()
					end, "Goto references")
					map("gI", function()
						Snacks.picker.lsp_implementations()
					end, "Goto implementation")
					map("gD", vim.lsp.buf.declaration, "Goto declaration")
					-- vim.diagnostic.jump replaces deprecated goto_next/goto_prev (removed in 0.13).
					map("ge", function()
						vim.diagnostic.jump({ count = 1, float = true })
					end, "Next diagnostic")
					map("gE", function()
						vim.diagnostic.jump({ count = -1, float = true })
					end, "Previous diagnostic")

					map("<leader>lD", function()
						Snacks.picker.lsp_type_definitions()
					end, "Type definition")
					-- Snacks source is lsp_symbols (not lsp_document_symbols).
					map("<leader>ls", function()
						Snacks.picker.lsp_symbols()
					end, "Document symbols")
					map("<leader>lS", function()
						Snacks.picker.lsp_workspace_symbols()
					end, "Workspace symbols")
					map("<leader>lr", vim.lsp.buf.rename, "Rename")
					map("<leader>la", vim.lsp.buf.code_action, "Code action", { "n", "x" })
					map("<leader>ll", vim.lsp.codelens.run, "Run codelens")
					map("K", vim.lsp.buf.hover, "Hover docs")

					local client = vim.lsp.get_client_by_id(event.data.client_id)
					-- Method form client:supports_method; dot form is deprecated for 0.13.
					if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
						local hl_group = vim.api.nvim_create_augroup("lsp_highlight_" .. buf, { clear = true })
						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = buf,
							group = hl_group,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = buf,
							group = hl_group,
							callback = vim.lsp.buf.clear_references,
						})
						vim.api.nvim_create_autocmd("LspDetach", {
							buffer = buf,
							group = vim.api.nvim_create_augroup("lsp_detach_" .. buf, { clear = true }),
							callback = function()
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = hl_group })
							end,
						})
					end
				end,
			})

			local capabilities = vim.tbl_deep_extend(
				"force",
				vim.lsp.protocol.make_client_capabilities(),
				require("blink.cmp").get_lsp_capabilities()
			)

			local servers = {
				gopls = {
					settings = {
						gopls = {
							analyses = { unusedparams = true },
							staticcheck = true,
							gofumpt = true,
						},
					},
				},
				ts_ls = {},
				pyright = {},
				lua_ls = {
					settings = {
						Lua = {
							completion = { callSnippet = "Replace" },
							diagnostics = { disable = { "missing-fields" } },
							workspace = { checkThirdParty = false },
						},
					},
				},
				html = {},
				cssls = {},
				jsonls = {},
				yamlls = {},
				bashls = {},
				dockerls = {},
				nil_ls = {},
			}

			-- Do not call mason.setup() here — lazy already did via opts (double setup duplicates registries).
			local ensure_installed = vim.tbl_keys(servers)
			vim.list_extend(ensure_installed, {
				"stylua",
				"prettierd",
				"black",
				"isort",
				"gofumpt",
				"goimports",
				"nixfmt",
				"markdownlint",
				"biome",
				"delve",
				"debugpy",
				"js-debug-adapter",
			})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			-- automatic_enable off: servers table is the single source of truth.
			-- mason-lspconfig still needed so mason-tool-installer can map lspconfig ↔ package names.
			require("mason-lspconfig").setup({ automatic_enable = false })

			vim.lsp.config("*", { capabilities = capabilities })

			for name, cfg in pairs(servers) do
				if next(cfg) ~= nil then
					vim.lsp.config(name, cfg)
				end
			end

			vim.lsp.enable(vim.tbl_keys(servers))
		end,
	},

	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>lf",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = { "n", "v" },
				desc = "LSP: Format buffer",
			},
		},
		opts = {
			notify_on_error = false,
			format_on_save = function(bufnr)
				local disable_filetypes = { c = true, cpp = true }
				return {
					timeout_ms = 500,
					lsp_format = disable_filetypes[vim.bo[bufnr].filetype] and "never" or "fallback",
				}
			end,
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				javascript = { "biome" },
				typescript = { "biome" },
				typescriptreact = { "biome" },
				javascriptreact = { "biome" },
				json = { "biome" },
				jsonc = { "biome" },
				yaml = { "prettierd" },
				markdown = { "prettierd" },
				go = { "goimports", "gofumpt" },
				nix = { "nixfmt" },
			},
		},
	},

	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")
			lint.linters_by_ft = {
				markdown = { "markdownlint" },
				javascript = { "biomejs" },
				typescript = { "biomejs" },
				typescriptreact = { "biomejs" },
				javascriptreact = { "biomejs" },
			}
			local augroup = vim.api.nvim_create_augroup("lint_on_save", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				group = augroup,
				callback = function()
					if vim.opt_local.modifiable:get() then
						lint.try_lint()
					end
				end,
			})
		end,
	},

	{
		"saghen/blink.cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		-- 1.x tags ship prebuilt fuzzy binaries; main would require a local Rust build.
		version = "1.*",
		dependencies = {
			"rafamadriz/friendly-snippets",
			"windwp/nvim-autopairs",
		},
		opts = {
			enabled = function()
				return not vim.tbl_contains({ "minifiles", "minifiles-help" }, vim.bo.filetype)
			end,
			keymap = {
				preset = "default",
				["<C-y>"] = { "select_and_accept" },
				["<C-n>"] = { "select_next", "fallback" },
				["<C-p>"] = { "select_prev", "fallback" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide" },
			},
			appearance = {
				use_nvim_cmp_as_default = false,
				nerd_font_variant = "mono",
			},
			sources = {
				default = { "lazydev", "lsp", "path", "snippets", "buffer", "dadbod" },
				providers = {
					lazydev = {
						name = "LazyDev",
						module = "lazydev.integrations.blink",
						score_offset = 100,
					},
					dadbod = {
						name = "Dadbod",
						module = "vim_dadbod_completion.blink",
					},
				},
			},
			completion = {
				accept = {
					create_undo_point = true,
					auto_brackets = {
						enabled = true,
					},
				},
				documentation = {
					auto_show = true,
					auto_show_delay_ms = 200,
				},
				ghost_text = { enabled = true },
			},
		},
	},
}
