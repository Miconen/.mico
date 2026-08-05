-- plugins/lsp.lua

-- selene: allow(unused_variable, shadowing)
-- Both are false positives here, and deleting the local below WILL break every
-- LSP keymap. A Lua local is not in scope until after its own statement, so the
-- `map(...)` call inside the inner `local map = function(...)` further down
-- resolves to THIS binding, not to itself. Verified with luajit:
--   local m = function(a) return "OUTER("..a..")" end
--   local m = function(a) return m(a).."+inner" end
--   print(m("x"))  --> OUTER(x)+inner
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

	-- Mason <-> lspconfig bridge
	{ "mason-org/mason-lspconfig.nvim", lazy = true },

	-- Ensures formatters/linters are installed via mason
	{ "WhoIsSethDaniel/mason-tool-installer.nvim", lazy = true },

	-- LSP configuration
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
					-- false on purpose: true recomputes and redraws diagnostics on every
					-- keystroke, which is the single most expensive default in this config
					-- on modest hardware. Diagnostics still refresh on InsertLeave.
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

			-- ── LspAttach: buffer-local keymaps ────────────────────────────────────
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("lsp_attach_keymaps", { clear = true }),
				callback = function(event)
					local buf = event.buf
					-- selene: allow(shadowing)
					-- Intentional: this wraps the outer `map` (vim.keymap.set) to add the
					-- buffer and an "LSP: " description prefix. See the note at the top.
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
					-- goto_next/goto_prev are vim.deprecate(..., "0.13"), i.e. removed in the
					-- next release. jump() is the replacement; float = true reproduces what
					-- goto_next did by default.
					map("ge", function()
						vim.diagnostic.jump({ count = 1, float = true })
					end, "Next diagnostic")
					map("gE", function()
						vim.diagnostic.jump({ count = -1, float = true })
					end, "Previous diagnostic")

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
					-- client:supports_method, not client.supports_method. The dot form still
					-- works via a compatibility shim in 0.12, but that shim calls
					-- vim.deprecate(..., "0.13") and goes away in the next release.
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
			-- mason.setup() is NOT called here. mason.nvim is declared as a dependency
			-- with its own `opts`, so lazy has already set it up before this config
			-- function runs. Calling setup() again appends every configured registry to
			-- Registry.sources a second time.
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

			-- mason-lspconfig 2.x. Its `handlers` table is gone; it can now enable
			-- servers itself via automatic_enable, but that keys off whatever happens to
			-- be installed in Mason. Turning it off keeps the `servers` table above as
			-- the single source of truth. It is still set up because mason-tool-installer
			-- relies on it to translate lspconfig names (lua_ls) into Mason package names
			-- (lua-language-server).
			require("mason-lspconfig").setup({ automatic_enable = false })

			-- Shared capabilities for every server. "*" is a real wildcard config in
			-- vim.lsp, not a server name.
			vim.lsp.config("*", { capabilities = capabilities })

			-- Per-server overrides. The base config for each of these ships with
			-- nvim-lspconfig as lsp/<name>.lua and is picked up off the runtimepath by
			-- Neovim itself, so only the deltas belong here.
			for name, cfg in pairs(servers) do
				if next(cfg) ~= nil then
					vim.lsp.config(name, cfg)
				end
			end

			vim.lsp.enable(vim.tbl_keys(servers))
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
		-- Pinned to the 1.x tag series rather than the main branch: tagged releases
		-- ship prebuilt fuzzy-matcher binaries, whereas tracking main means building
		-- the Rust matcher locally.
		version = "1.*",
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
