-- plugins/lsp.lua
local map = vim.keymap.set

return {
	-- Lua LSP awareness of Neovim runtime/APIs
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

	-- Mason: install/manage LSP servers, formatters, linters
	{
		"williamboman/mason.nvim",
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

	-- Mason <-> lspconfig bridge
	{ "williamboman/mason-lspconfig.nvim", lazy = true },

	-- Ensures formatters/linters are installed via mason
	{ "WhoIsSethDaniel/mason-tool-installer.nvim", lazy = true },

	-- LSP configuration
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			"saghen/blink.cmp",
		},
		config = function()
			-- ── Diagnostic signs & config ──────────────────────────────────────────
			if vim.g.have_nerd_font then
				local signs = { ERROR = "󰊠", WARN = "󰊠", INFO = "", HINT = "" }
				local diagnostic_signs = {}
				for type, icon in pairs(signs) do
					diagnostic_signs[vim.diagnostic.severity[type]] = icon
				end
				vim.diagnostic.config({
					signs = { text = diagnostic_signs },
					virtual_text = true,
					underline = true,
					severity_sort = true,
					update_in_insert = true,
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

			-- ── LspAttach: buffer-local keymaps ────────────────────────────────────
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp_attach_keymaps", { clear = true }),
				callback = function(event)
					local buf = event.buf
					local map = function(keys, func, desc, mode)
						map(mode or "n", keys, func, { buffer = buf, desc = "LSP: " .. desc })
					end

					-- Navigation
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
					map("ge", vim.diagnostic.goto_next, "Next diagnostic")
					map("gE", vim.diagnostic.goto_prev, "Previous diagnostic")

					-- LSP actions (<leader>l group label set in keymaps/lsp.lua)
					map("<leader>lD", function()
						Snacks.picker.lsp_type_definitions()
					end, "Type definition")
					map("<leader>ls", function()
						Snacks.picker.lsp_document_symbols()
					end, "Document symbols")
					map("<leader>lS", function()
						Snacks.picker.lsp_workspace_symbols()
					end, "Workspace symbols")
					map("<leader>lr", vim.lsp.buf.rename, "Rename")
					map("<leader>la", vim.lsp.buf.code_action, "Code action", { "n", "x" })
					map("<leader>ll", vim.lsp.codelens.run, "Run codelens")
					map("K", vim.lsp.buf.hover, "Hover docs")

					-- Document highlight on cursor hold
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if client and client.supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
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

			-- ── Server capabilities (shared, extended by blink.cmp) ───────────────
			local capabilities = vim.tbl_deep_extend(
				"force",
				vim.lsp.protocol.make_client_capabilities(),
				require("blink.cmp").get_lsp_capabilities()
			)

			-- ── Server definitions ─────────────────────────────────────────────────
			local servers = {
				-- Go
				gopls = {
					settings = {
						gopls = {
							analyses = { unusedparams = true },
							staticcheck = true,
							gofumpt = true,
						},
					},
				},
				-- TypeScript / JavaScript
				ts_ls = {},
				-- Python
				pyright = {},
				-- Lua
				lua_ls = {
					settings = {
						Lua = {
							completion = { callSnippet = "Replace" },
							diagnostics = { disable = { "missing-fields" } },
							workspace = { checkThirdParty = false },
						},
					},
				},
				-- Web
				html = {},
				cssls = {},
				jsonls = {},
				yamlls = {},
				-- Misc
				bashls = {},
				dockerls = {},
			}

			-- ── Mason setup ────────────────────────────────────────────────────────
			require("mason").setup()

			local ensure_installed = vim.tbl_keys(servers)
			vim.list_extend(ensure_installed, {
				-- Formatters
				"stylua",
				"prettierd",
				"black",
				"isort",
				"gofumpt",
				"goimports",
				-- Linters
				"markdownlint",
				"biome",
				-- Debuggers
				"delve",
				"debugpy",
				"js-debug-adapter",
			})
			require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

			require("mason-lspconfig").setup({
				handlers = {
					function(server_name)
						local server = servers[server_name] or {}
						server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
						require("lspconfig")[server_name].setup(server)
					end,
				},
			})
		end,
	},

	-- Formatter
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
				javascript = { "prettierd", stop_after_first = true },
				typescript = { "prettierd", stop_after_first = true },
				typescriptreact = { "prettierd", stop_after_first = true },
				javascriptreact = { "prettierd", stop_after_first = true },
				json = { "prettierd" },
				yaml = { "prettierd" },
				markdown = { "prettierd" },
				go = { "goimports", "gofumpt" },
			},
		},
	},

	-- Linter
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

	-- blink.cmp: completion
	{
		"saghen/blink.cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		version = "v0.*",
		dependencies = {
			"rafamadriz/friendly-snippets",
			-- Autopairs integration
			"windwp/nvim-autopairs",
		},
		opts = {
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
						score_offset = 100, -- prioritise lazydev over lsp for lua
					},
					dadbod = {
						name = "Dadbod",
						module = "vim_dadbod_completion.blink",
					},
				},
			},
			completion = {
				accept = {
					-- Integrate with autopairs
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
