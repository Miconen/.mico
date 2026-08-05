-- plugins/debug.lua
local icons = require("keymaps.icons")

---nvim-dap-view indexes dap.listeners.on_session at require-time (not setup).
---Older nvim-dap only has before/after/on_config. Ensure the tables exist first.
local function ensure_dap_view_compat()
	local dap = require("dap")
	local listeners = dap.listeners
	if listeners.on_session == nil then
		listeners.on_session = {}
	end
	if listeners.on_config == nil then
		listeners.on_config = {}
	end
	return dap
end

return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"theHamsta/nvim-dap-virtual-text",
			"mason-org/mason.nvim",
			"leoluz/nvim-dap-go",
			"mfussenegger/nvim-dap-python",
		},
		keys = {
			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "Toggle breakpoint",
			},
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input("Condition: "))
				end,
				desc = "Conditional breakpoint",
			},
			{
				"<leader>dc",
				function()
					require("dap").continue()
				end,
				desc = "Continue",
			},
			{
				"<leader>dn",
				function()
					require("dap").step_over()
				end,
				desc = "Step over",
			},
			{
				"<leader>di",
				function()
					require("dap").step_into()
				end,
				desc = "Step into",
			},
			{
				"<leader>do",
				function()
					require("dap").step_out()
				end,
				desc = "Step out",
			},
			{
				"<leader>dt",
				function()
					require("dap").terminate()
				end,
				desc = "Terminate",
			},
		},
		config = function()
			local dap = require("dap")
			require("nvim-dap-virtual-text").setup()

			vim.fn.sign_define("DapBreakpoint", {
				text = icons.DapBreakpoint,
				texthl = "DiagnosticError",
				linehl = "",
				numhl = "",
			})
			vim.fn.sign_define("DapBreakpointCondition", {
				text = icons.DapBreakpointCondition,
				texthl = "DiagnosticWarn",
				linehl = "",
				numhl = "",
			})
			vim.fn.sign_define("DapBreakpointRejected", {
				text = icons.DapBreakpointRejected,
				texthl = "DiagnosticError",
				linehl = "",
				numhl = "",
			})
			vim.fn.sign_define("DapLogPoint", {
				text = icons.DapLogPoint,
				texthl = "DiagnosticInfo",
				linehl = "",
				numhl = "",
			})
			vim.fn.sign_define("DapStopped", {
				text = icons.DapStopped,
				texthl = "DiagnosticWarn",
				linehl = "Visual",
				numhl = "DiagnosticWarn",
			})

			require("dap-go").setup({
				dap_configurations = {
					{
						type = "go",
						name = "Attach remote",
						mode = "remote",
						request = "attach",
					},
				},
				delve = {
					port = "${port}",
					args = {},
				},
			})

			require("dap-python").setup(vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python")

			-- JS/TS via mason js-debug-adapter (vscode-js-debug).
			--
			-- tsx is almost never on PATH — only node_modules/.bin/tsx. Bare
			-- runtimeExecutable="tsx" makes the adapter spawn fail → "Debug adapter disconnected".
			--
			-- console=integratedTerminal creates a term_buf; dap-view's dap-defaults
			-- sets terminal_win_cmd to a hidden buffer, and the Console section shows it
			-- (no extra split when terminal.hide = true and console is in winbar.sections).
			local js_debug = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
			if vim.uv.fs_stat(js_debug) or vim.fn.filereadable(js_debug) == 1 then
				-- Pick a real free port. Some nvim-dap builds leave "${port}" unexpanded in the
				-- connect address ("couldn't connect to 127.0.0.1:${port}").
				local function free_port()
					local uv = vim.uv or vim.loop
					local server = uv.new_tcp()
					assert(server, "uv.new_tcp failed")
					assert(server:bind("127.0.0.1", 0))
					local sock = server:getsockname()
					server:close()
					return sock.port
				end

				local function pwa_adapter(callback)
					local port = free_port()
					callback({
						type = "server",
						host = "127.0.0.1",
						port = port,
						executable = {
							command = "node",
							args = { js_debug, tostring(port) },
						},
					})
				end

				dap.adapters["pwa-node"] = pwa_adapter
				dap.adapters["pwa-chrome"] = pwa_adapter

				local source_maps = {
					sourceMaps = true,
					resolveSourceMapLocations = {
						"${workspaceFolder}/**",
						"!**/node_modules/**",
					},
					outFiles = {
						"${workspaceFolder}/**/*.(m|c|)js",
						"!**/node_modules/**",
					},
					skipFiles = {
						"<node_internals>/**",
						"${workspaceFolder}/node_modules/**",
						"**/node_modules/**",
					},
				}

				---Resolve project-local tsx; never rely on PATH.
				local function local_tsx()
					local root = vim.fn.getcwd()
					local candidates = {
						root .. "/node_modules/.bin/tsx",
						root .. "/node_modules/tsx/dist/cli.mjs",
					}
					for _, path in ipairs(candidates) do
						if vim.fn.filereadable(path) == 1 or vim.fn.executable(path) == 1 then
							return path
						end
					end
					return nil
				end

				-- Enrich launch configs that ask for local tsx before the adapter runs.
				dap.listeners.on_config = dap.listeners.on_config or {}
				dap.listeners.on_config["mico_tsx_resolve"] = function(config)
					if not config.mico_use_local_tsx then
						return config
					end
					local tsx = local_tsx()
					if not tsx then
						vim.notify(
							"tsx not found under "
								.. vim.fn.getcwd()
								.. "/node_modules — run npm i and open nvim from the project root",
							vim.log.levels.ERROR
						)
						return config
					end
					config = vim.deepcopy(config)
					config.runtimeExecutable = tsx
					config.mico_use_local_tsx = nil
					return config
				end

				local function launch(cfg)
					return vim.tbl_deep_extend("force", {
						type = "pwa-node",
						request = "launch",
						cwd = "${workspaceFolder}",
						console = "integratedTerminal",
						autoAttachChildProcesses = true,
					}, source_maps, cfg)
				end

				local function attach(cfg)
					return vim.tbl_deep_extend("force", {
						type = "pwa-node",
						request = "attach",
						cwd = "${workspaceFolder}",
					}, source_maps, cfg)
				end

				local function launch_tsx(cfg)
					cfg.mico_use_local_tsx = true
					-- runtimeExecutable filled in on_config from node_modules
					cfg.runtimeExecutable = "tsx"
					return launch(cfg)
				end

				local js_ts = {
					launch_tsx({
						name = "tsx: src/main.ts",
						args = { "${workspaceFolder}/src/main.ts" },
					}),
					launch_tsx({
						name = "tsx: current file",
						args = { "${file}" },
					}),
					launch_tsx({
						name = "tsx watch: src/main.ts",
						args = { "watch", "${workspaceFolder}/src/main.ts" },
						restart = true,
					}),
					-- npm finds local bins via the script PATH
					launch({
						name = "npm: run dev",
						runtimeExecutable = "npm",
						runtimeArgs = { "run", "dev" },
						restart = true,
					}),
					launch({
						name = "npm: start",
						runtimeExecutable = "npm",
						runtimeArgs = { "start" },
					}),
					launch({
						name = "npm: test",
						runtimeExecutable = "npm",
						runtimeArgs = { "test" },
					}),
					launch({
						name = "node: current file (JS only)",
						program = "${file}",
					}),
					attach({
						name = "Attach (pick process)",
						processId = require("dap.utils").pick_process,
					}),
					attach({
						name = "Attach port 9229",
						address = "127.0.0.1",
						port = 9229,
					}),
				}

				for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
					dap.configurations[language] = js_ts
				end
			end
		end,
	},
	{
		"igorlfs/nvim-dap-view",
		dependencies = { "mfussenegger/nvim-dap" },
		keys = {
			{
				"<leader>dv",
				function()
					require("dap-view").toggle()
				end,
				desc = "Toggle DAP view",
			},
		},
		opts = {
			winbar = {
				show = true,
				show_keymap_hints = true,
				-- One window: cycle with Tab / 1-4 (see keymaps + base_sections)
				sections = { "scopes", "watches", "repl", "console" },
				default_section = "scopes",
				base_sections = {
					scopes = { label = "Scopes", keymap = "1" },
					watches = { label = "Watches", keymap = "2" },
					repl = { label = "REPL", keymap = "3" },
					console = { label = "Console", keymap = "4" },
				},
			},
			windows = {
				position = "right",
				size = 0.33,
				terminal = {
					-- Console lives in the winbar section above — no separate split
					hide = true,
					position = "below",
					size = 0.25,
				},
			},
			keymaps = {
				base = {
					next_view = { "]v", "<Tab>" },
					prev_view = { "[v", "<S-Tab>" },
				},
			},
		},
		-- Must shim before require("dap-view"): listeners.lua runs at import time.
		config = function(_, opts)
			for name in pairs(package.loaded) do
				if name == "dap-view" or vim.startswith(name, "dap-view.") then
					package.loaded[name] = nil
				end
			end
			ensure_dap_view_compat()
			require("dap-view").setup(opts)
		end,
	},
}
