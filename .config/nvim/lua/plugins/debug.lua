-- plugins/debug.lua
local icons = require("keymaps.icons")

return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{
				"igorlfs/nvim-dap-view",
				opts = {},
			},
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
			{
				"<leader>dv",
				function()
					require("dap-view").toggle()
				end,
				desc = "Toggle DAP view",
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

			-- Go (TCP delve — more reliable under WSL than pipes)
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

			-- JS/TS via mason js-debug-adapter (vscode-js-debug)
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

				for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
					dap.configurations[language] = {
						{
							type = "pwa-node",
							request = "launch",
							name = "Launch file",
							program = "${file}",
							cwd = "${workspaceFolder}",
						},
						{
							type = "pwa-node",
							request = "attach",
							name = "Attach",
							processId = require("dap.utils").pick_process,
							cwd = "${workspaceFolder}",
						},
					}
				end
			end
		end,
	},
}
