local map = vim.keymap.set

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

autocmd("TextYankPost", {
	group = augroup("highlight_yank", { clear = true }),
	desc = "Highlight when yanking text",
	callback = function()
		vim.hl.on_yank()
	end,
})

autocmd("VimResized", {
	group = augroup("resize_splits", { clear = true }),
	desc = "Resize splits on window resize",
	callback = function()
		vim.cmd("tabdo wincmd =")
	end,
})

autocmd("FileType", {
	group = augroup("close_with_q", { clear = true }),
	desc = "Close certain buffers with q",
	pattern = {
		"help",
		"lspinfo",
		"notify",
		"qf",
		"checkhealth",
		"man",
		"mason",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		map("n", "q", "<cmd>close<cr>", {
			buffer = event.buf,
			silent = true,
			desc = "Close buffer",
		})
	end,
})

autocmd("BufReadPost", {
	group = augroup("restore_cursor", { clear = true }),
	desc = "Restore cursor position",
	callback = function()
		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

autocmd("User", {
	group = augroup("mini_files_lsp_rename", { clear = true }),
	pattern = "MiniFilesActionRename",
	callback = function(event)
		local ok = pcall(require, "snacks")
		if ok then
			Snacks.rename.on_rename_file(event.data.from, event.data.to)
		end
	end,
})
