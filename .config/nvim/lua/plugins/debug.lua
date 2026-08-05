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
				"<leader>dr",
				function()
					require("dap").repl.open()
				end,
				desc = "Open REPL",
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
			-- Plain `node ${file}` does not read tsconfig paths or run .ts — use tsx
			-- (or attach to a process you started with the project's real entry).
			local js_debug = vim.fn.stdpath("data") .. "/mason/packages/js-debug-adapter/js-debug/src/dapDebugServer.js"
			if vim.uv.fs_stat(js_debug) or vim.fn.filereadable(js_debug) == 1 then
				dap.adapters["pwa-node"] = {
					type = "server",
					host = "localhost",
					port = "${port}",
					executable = {
						command = "node",
						args = { js_debug, "${port}" },
					},
				}
				dap.adapters["pwa-chrome"] = dap.adapters["pwa-node"]

				local js_ts = {
					{
						type = "pwa-node",
						request = "launch",
						name = "tsx: current file",
						runtimeExecutable = "tsx",
						runtimeArgs = { "--tsconfig", "${workspaceFolder}/tsconfig.json" },
						args = { "${file}" },
						cwd = "${workspaceFolder}",
						sourceMaps = true,
						resolveSourceMapLocations = {
							"${workspaceFolder}/**",
							"!**/node_modules/**",
						},
						skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
						console = "integratedTerminal",
					},
					{
						type = "pwa-node",
						request = "launch",
						name = "tsx: current file (no tsconfig flag)",
						runtimeExecutable = "tsx",
						args = { "${file}" },
						cwd = "${workspaceFolder}",
						sourceMaps = true,
						skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
						console = "integratedTerminal",
					},
					{
						type = "pwa-node",
						request = "launch",
						name = "node: current file (JS only)",
						program = "${file}",
						cwd = "${workspaceFolder}",
						sourceMaps = true,
						skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
						console = "integratedTerminal",
					},
					{
						type = "pwa-node",
						request = "launch",
						name = "npm: run dev",
						runtimeExecutable = "npm",
						runtimeArgs = { "run", "dev" },
						cwd = "${workspaceFolder}",
						console = "integratedTerminal",
						skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
					},
					{
						type = "pwa-node",
						request = "launch",
						name = "npm: test",
						runtimeExecutable = "npm",
						runtimeArgs = { "test" },
						cwd = "${workspaceFolder}",
						console = "integratedTerminal",
						skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
					},
					{
						type = "pwa-node",
						request = "attach",
						name = "Attach (pick process)",
						processId = require("dap.utils").pick_process,
						cwd = "${workspaceFolder}",
						sourceMaps = true,
						skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
					},
					{
						type = "pwa-node",
						request = "attach",
						name = "Attach port 9229",
						address = "localhost",
						port = 9229,
						cwd = "${workspaceFolder}",
						sourceMaps = true,
						skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },
					},
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
				sections = { "scopes", "repl" },
				default_section = "scopes",
			},
			windows = {
				-- Vertical sidebar on the right (~1/3 of the editor)
				position = "right",
				size = 0.33,
				terminal = {
					-- Keep the debug adapter console out of the way
					hide = true,
					position = "below",
					size = 0.25,
				},
			},
		},
		-- Must shim before require("dap-view"): listeners.lua runs at import time.
		config = function(_, opts)
			-- Clear a half-failed require from a previous error in this session.
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
