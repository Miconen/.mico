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
				"<leader>d<leader>",
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
			local js_debug_bin = vim.fn.stdpath("data") .. "/mason/bin/js-debug-adapter"
			if vim.uv.fs_stat(js_debug) or vim.fn.filereadable(js_debug) == 1 then
				-- dapDebugServer defaults to host "localhost" (often ::1). We must bind and
				-- connect on the same address or nvim-dap reports "Couldn't connect to 127.0.0.1:PORT".
				local function free_port()
					local uv = vim.uv or vim.loop
					local server = assert(uv.new_tcp())
					assert(server:bind("127.0.0.1", 0))
					local sock = assert(server:getsockname())
					server:close()
					return sock.port
				end

				local function pwa_adapter(callback)
					local port = free_port()
					local cmd, args
					if vim.fn.executable(js_debug_bin) == 1 then
						cmd = js_debug_bin
						args = { tostring(port), "127.0.0.1" }
					else
						cmd = "node"
						args = { js_debug, tostring(port), "127.0.0.1" }
					end
					callback({
						type = "server",
						host = "127.0.0.1",
						port = port,
						executable = {
							command = cmd,
							args = args,
						},
						options = {
							max_retries = 40,
						},
					})
				end

				dap.adapters["pwa-node"] = pwa_adapter
				dap.adapters["pwa-chrome"] = pwa_adapter

				local skip_files = {
					"<node_internals>/**",
					"${workspaceFolder}/node_modules/**",
					"**/node_modules/**",
				}

				-- Shared maps for attach / plain node. Do NOT set outFiles on tsx launches:
				-- tsx runs .ts in-process; pointing the adapter at emitted .js breaks BP binding
				-- and leaves you running with no pause → "No eligible scopes".
				local node_maps = {
					sourceMaps = true,
					resolveSourceMapLocations = {
						"${workspaceFolder}/**",
						"!**/node_modules/**",
					},
					outFiles = {
						"${workspaceFolder}/**/*.(m|c|)js",
						"!**/node_modules/**",
					},
					skipFiles = skip_files,
				}

				local tsx_maps = {
					sourceMaps = true,
					resolveSourceMapLocations = {
						"${workspaceFolder}/**",
						"!**/node_modules/**",
					},
					skipFiles = skip_files,
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

				-- Scopes only exist while paused. Open the panel on stop so it's obvious.
				dap.listeners.after.event_stopped["mico_open_dap_view"] = function()
					local ok, view = pcall(require, "dap-view")
					if ok then
						view.open()
					end
				end

				local function launch(cfg, maps)
					return vim.tbl_deep_extend("force", {
						type = "pwa-node",
						request = "launch",
						cwd = "${workspaceFolder}",
						console = "integratedTerminal",
					}, maps or node_maps, cfg)
				end

				local function attach(cfg)
					return vim.tbl_deep_extend("force", {
						type = "pwa-node",
						request = "attach",
						cwd = "${workspaceFolder}",
					}, node_maps, cfg)
				end

				local function launch_tsx(cfg)
					cfg.mico_use_local_tsx = true
					cfg.runtimeExecutable = "tsx"
					-- Direct tsx: stay on one session (child attach confuses scopes).
					cfg.autoAttachChildProcesses = false
					return launch(cfg, tsx_maps)
				end

				local js_ts = {
					launch_tsx({
						name = "tsx: src/main.ts",
						args = { "${workspaceFolder}/src/main.ts" },
						-- Pause immediately so Scopes has a frame (continue with <leader>dc).
						stopOnEntry = true,
					}),
					launch_tsx({
						name = "tsx: src/main.ts (no stop on entry)",
						args = { "${workspaceFolder}/src/main.ts" },
						stopOnEntry = false,
					}),
					launch_tsx({
						name = "tsx: current file",
						args = { "${file}" },
						stopOnEntry = true,
					}),
					launch_tsx({
						name = "tsx watch: src/main.ts",
						args = { "watch", "${workspaceFolder}/src/main.ts" },
						restart = true,
						autoAttachChildProcesses = true,
						stopOnEntry = false,
					}),
					launch({
						name = "npm: run dev",
						runtimeExecutable = "npm",
						runtimeArgs = { "run", "dev" },
						restart = true,
						autoAttachChildProcesses = true,
					}, node_maps),
					launch({
						name = "npm: start",
						runtimeExecutable = "npm",
						runtimeArgs = { "start" },
						autoAttachChildProcesses = true,
					}, node_maps),
					launch({
						name = "npm: test",
						runtimeExecutable = "npm",
						runtimeArgs = { "test" },
						autoAttachChildProcesses = true,
					}, node_maps),
					launch({
						name = "node: current file (JS only)",
						program = "${file}",
					}, node_maps),
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
				sections = { "scopes", "watches", "repl", "console", "sessions" },
				default_section = "scopes",
				base_sections = {
					scopes = { label = "Scopes", keymap = "1" },
					watches = { label = "Watches", keymap = "2" },
					repl = { label = "REPL", keymap = "3" },
					console = { label = "Console", keymap = "4" },
					sessions = { label = "Sessions", keymap = "5" },
				},
			},
			windows = {
				position = "right",
				size = 0.33,
				terminal = {
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
