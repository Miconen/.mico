-- autocmds.lua
local map = vim.keymap.set

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Highlight on yank
autocmd("TextYankPost", {
	group = augroup("highlight_yank", { clear = true }),
	desc = "Highlight when yanking text",
	callback = function()
		vim.highlight.on_yank()
	end,
})

-- Remove trailing whitespace on save
autocmd("BufWritePre", {
	group = augroup("trim_whitespace", { clear = true }),
	desc = "Remove trailing whitespace on save",
	callback = function()
		local pos = vim.api.nvim_win_get_cursor(0)
		vim.cmd([[%s/\s\+$//e]])
		vim.api.nvim_win_set_cursor(0, pos)
	end,
})

-- Resize splits when window is resized
autocmd("VimResized", {
	group = augroup("resize_splits", { clear = true }),
	desc = "Resize splits on window resize",
	callback = function()
		vim.cmd("tabdo wincmd =")
	end,
})

-- Close certain filetypes with just q
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

-- Restore cursor position on file open
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

-- mini.files: notify LSP on rename
autocmd("User", {
	group = augroup("mini_files_lsp_rename", { clear = true }),
	pattern = "MiniFilesActionRename",
	callback = function(event)
		local ok, snacks = pcall(require, "snacks")
		if ok then
			Snacks.rename.on_rename_file(event.data.from, event.data.to)
		end
	end,
})
