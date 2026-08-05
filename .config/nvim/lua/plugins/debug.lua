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

---True when dap-view's main window is open (safe if plugin not loaded).
local function dap_view_is_open()
	local ok_state, state = pcall(require, "dap-view.state")
	local ok_util, util = pcall(require, "dap-view.util")
	return ok_state and ok_util and util.is_win_valid(state.winnr)
end

local DAP_VIEW_SECTIONS = { "scopes", "watches", "repl", "console", "sessions" }

---1-5 switch dap-view sections only while a session is active (no clash with counts offline).
local function setup_dap_view_section_keys()
	local dap = require("dap")
	local mapped = false

	local function enable()
		if mapped then
			return
		end
		mapped = true
		for i, section in ipairs(DAP_VIEW_SECTIONS) do
			vim.keymap.set("n", tostring(i), function()
				local view = require("dap-view")
				if not dap_view_is_open() then
					view.open()
				end
				view.show_view(section)
			end, { desc = "DAP view: " .. section, silent = true })
		end
	end

	local function disable()
		if not mapped then
			return
		end
		mapped = false
		for i = 1, #DAP_VIEW_SECTIONS do
			pcall(vim.keymap.del, "n", tostring(i))
		end
	end

	dap.listeners.after.event_initialized["mico_dap_view_keys"] = enable
	dap.listeners.after.event_stopped["mico_dap_view_keys"] = enable
	dap.listeners.after.event_terminated["mico_dap_view_keys"] = function()
		if not dap.session() then
			disable()
		end
	end
	dap.listeners.after.event_exited["mico_dap_view_keys"] = function()
		if not dap.session() then
			disable()
		end
	end
	dap.listeners.after.disconnect["mico_dap_view_keys"] = function()
		if not dap.session() then
			disable()
		end
	end
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
			setup_dap_view_section_keys()

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
			-- Critical: launch with `node --import tsx` + `program`, NOT runtimeExecutable=tsx.
			-- The tsx CLI often runs user code in a child process that never gets inspect-brk,
			-- so stopOnEntry/breakpoints are ignored while the console still prints output.
			local js_debug = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
			local js_debug_bin = vim.fn.stdpath("data") .. "/mason/bin/js-debug-adapter"
			if vim.uv.fs_stat(js_debug) or vim.fn.filereadable(js_debug) == 1 then
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

				local ts_maps = {
					sourceMaps = true,
					resolveSourceMapLocations = {
						"${workspaceFolder}/**",
						"!**/node_modules/**",
					},
					skipFiles = skip_files,
				}

				---Ensure project-local tsx exists (node resolves --import tsx from cwd).
				local function assert_local_tsx()
					local root = vim.fn.getcwd()
					local pkg = root .. "/node_modules/tsx/package.json"
					if vim.fn.filereadable(pkg) == 0 then
						vim.notify(
							"tsx package not found under "
								.. root
								.. "/node_modules — run npm i and open nvim from the project root",
							vim.log.levels.ERROR
						)
						return false
					end
					return true
				end

				dap.listeners.on_config = dap.listeners.on_config or {}
				dap.listeners.on_config["mico_tsx_check"] = function(config)
					if config.mico_require_tsx and not assert_local_tsx() then
						return config
					end
					config = vim.deepcopy(config)
					config.mico_require_tsx = nil
					return config
				end

				dap.listeners.after.event_stopped["mico_open_dap_view"] = function()
					local ok, view = pcall(require, "dap-view")
					if ok then
						view.open()
						view.show_view("scopes")
					end
				end

				local function launch(cfg)
					return vim.tbl_deep_extend("force", {
						type = "pwa-node",
						request = "launch",
						cwd = "${workspaceFolder}",
						console = "integratedTerminal",
					}, ts_maps, cfg)
				end

				local function attach(cfg)
					return vim.tbl_deep_extend("force", {
						type = "pwa-node",
						request = "attach",
						cwd = "${workspaceFolder}",
					}, ts_maps, cfg)
				end

				-- node --import tsx <program>: one process, js-debug can inject inspect-brk.
				local function launch_tsx(cfg)
					return launch(vim.tbl_deep_extend("force", {
						mico_require_tsx = true,
						runtimeExecutable = "node",
						runtimeArgs = { "--import", "tsx" },
						autoAttachChildProcesses = false,
					}, cfg))
				end

				local js_ts = {
					launch_tsx({
						name = "tsx: src/main.ts",
						program = "${workspaceFolder}/src/main.ts",
						stopOnEntry = true,
					}),
					launch_tsx({
						name = "tsx: src/main.ts (no stop on entry)",
						program = "${workspaceFolder}/src/main.ts",
						stopOnEntry = false,
					}),
					launch_tsx({
						name = "tsx: current file",
						program = "${file}",
						stopOnEntry = true,
					}),
					-- npm / watch still need child attach
					launch({
						name = "npm: run dev",
						runtimeExecutable = "npm",
						runtimeArgs = { "run", "dev" },
						restart = true,
						autoAttachChildProcesses = true,
					}),
					launch({
						name = "npm: start",
						runtimeExecutable = "npm",
						runtimeArgs = { "start" },
						autoAttachChildProcesses = true,
					}),
					launch({
						name = "npm: test",
						runtimeExecutable = "npm",
						runtimeArgs = { "test" },
						autoAttachChildProcesses = true,
					}),
					launch({
						name = "node: current file (JS only)",
						program = "${file}",
						runtimeExecutable = "node",
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
