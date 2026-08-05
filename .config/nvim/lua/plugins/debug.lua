-- plugins/debug.lua
local icons = require("keymaps.icons")

local function ensure_dap_view_compat()
	local dap = require("dap")
	if dap.listeners.on_session == nil then
		dap.listeners.on_session = {}
	end
	if dap.listeners.on_config == nil then
		dap.listeners.on_config = {}
	end
	return dap
end

local function dap_view_is_open()
	local ok_state, state = pcall(require, "dap-view.state")
	local ok_util, util = pcall(require, "dap-view.util")
	return ok_state and ok_util and util.is_win_valid(state.winnr)
end

local DAP_VIEW_SECTIONS = { "scopes", "watches", "repl", "console", "sessions" }

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

	local function maybe_disable()
		if not dap.session() then
			disable()
		end
	end

	dap.listeners.after.event_initialized["mico_dap_view_keys"] = enable
	dap.listeners.after.event_stopped["mico_dap_view_keys"] = enable
	dap.listeners.after.event_terminated["mico_dap_view_keys"] = maybe_disable
	dap.listeners.after.event_exited["mico_dap_view_keys"] = maybe_disable
	dap.listeners.after.disconnect["mico_dap_view_keys"] = maybe_disable
end

local function setup_js_ts_dap(dap)
	local data = vim.fn.stdpath("data")
	local js_debug = data .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
	local js_debug_bin = data .. "/mason/bin/js-debug-adapter"

	-- Discover the real script path (mason layout varies slightly by version).
	if vim.fn.filereadable(js_debug) == 0 then
		local alt = {
			data .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js",
			data .. "/mason/packages/js-debug-adapter/src/dapDebugServer.js",
		}
		local ok, registry = pcall(require, "mason-registry")
		if ok and registry.has_package("js-debug-adapter") then
			local pkg = registry.get_package("js-debug-adapter")
			if pkg:is_installed() then
				table.insert(alt, 1, pkg:get_install_path() .. "/js-debug/src/dapDebugServer.js")
			end
		end
		for _, p in ipairs(alt) do
			if vim.fn.filereadable(p) == 1 then
				js_debug = p
				break
			end
		end
	end

	local has_js = vim.fn.filereadable(js_debug) == 1 or vim.fn.executable(js_debug_bin) == 1
	if not has_js then
		vim.notify("js-debug-adapter not found — run :MasonInstall js-debug-adapter", vim.log.levels.WARN)
		return
	end

	-- Standard nvim-dap ${port} substitution. Both the connect host and the
	-- server listen address must agree. Do not pre-bind a port yourself — that
	-- races with the server process and yields "Couldn't connect to 127.0.0.1:PORT".
	local cmd = "node"
	local args = { js_debug, "${port}" }
	if vim.fn.executable(js_debug_bin) == 1 then
		cmd = js_debug_bin
		args = { "${port}" }
	end

	local adapter = {
		type = "server",
		host = "localhost",
		port = "${port}",
		executable = {
			command = cmd,
			args = args,
			detached = true,
		},
		options = {
			max_retries = 50,
		},
	}
	dap.adapters["pwa-node"] = adapter
	dap.adapters["pwa-chrome"] = vim.deepcopy(adapter)

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

	local function assert_local_tsx()
		local root = vim.fn.getcwd()
		if vim.fn.filereadable(root .. "/node_modules/tsx/package.json") == 0 then
			vim.notify(
				"tsx not found under " .. root .. "/node_modules — run npm i and open nvim from the project root",
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

	-- node --import tsx <program>: one process; js-debug injects inspect-brk.
	-- node resolves the `tsx` package from cwd/node_modules.
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
			setup_js_ts_dap(dap)
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
