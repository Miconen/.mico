-- Breadcrumb: cwd › dirs › file › LSP symbol

local M = {}

local SKIP_FT = {
	[""] = true,
	help = true,
	lazy = true,
	mason = true,
	minifiles = true,
	checkhealth = true,
	man = true,
	qf = true,
	-- These plugins draw their own winbars.
	["dap-view"] = true,
	["dap-view-term"] = true,
	["dap-view-hover"] = true,
	["dap-view-help"] = true,
	["dap-repl"] = true,
	["grug-far"] = true,
	["grug-far-history"] = true,
	["grug-far-help"] = true,
}

local FOLDER = "󰉋 "
local SEP = " › "

local function set_hls()
	vim.api.nvim_set_hl(0, "WinBarSep", { link = "NonText" })
	vim.api.nvim_set_hl(0, "WinBarDir", { link = "Directory" })
	vim.api.nvim_set_hl(0, "WinBarFile", { link = "Normal" })
	vim.api.nvim_set_hl(0, "NavicSeparator", { link = "NonText" })
end
set_hls()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hls })

local function hlfmt(group, text)
	return "%#" .. group .. "#" .. text .. "%*"
end

-- Cached per buffer; only the navic part changes on cursor movement.
local function build_prefix()
	local fullpath = vim.fn.expand("%:p")
	if fullpath == "" then
		return nil
	end

	local cwd_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	local relative = vim.fn.fnamemodify(fullpath, ":.")
	local filename = vim.fn.fnamemodify(fullpath, ":t")
	local rel_dir = vim.fn.fnamemodify(relative, ":h")

	local file_icon = ""
	local file_icon_hl = "WinBarFile"
	local icons_ok, icons = pcall(require, "mini.icons")
	if icons_ok then
		local icon, icon_hl = icons.get("file", filename)
		file_icon = icon .. " "
		file_icon_hl = icon_hl
	end

	local parts = {}

	table.insert(parts, hlfmt("WinBarDir", FOLDER .. cwd_name))

	if rel_dir ~= "." and rel_dir ~= "" then
		for seg in rel_dir:gmatch("[^/\\]+") do
			table.insert(parts, hlfmt("WinBarSep", SEP))
			table.insert(parts, hlfmt("WinBarDir", FOLDER .. seg))
		end
	end

	table.insert(parts, hlfmt("WinBarSep", SEP))
	table.insert(parts, hlfmt(file_icon_hl, file_icon) .. hlfmt("WinBarFile", filename))

	return " " .. table.concat(parts)
end

local function prefix()
	if vim.b.winbar_prefix == nil then
		-- false caches "no prefix" for unnamed buffers.
		vim.b.winbar_prefix = build_prefix() or false
	end
	if vim.b.winbar_prefix == false then
		return nil
	end
	return vim.b.winbar_prefix
end

local function build()
	if SKIP_FT[vim.bo.filetype] or vim.bo.buftype ~= "" then
		return ""
	end

	local head = prefix()
	if not head then
		return ""
	end

	local navic_ok, navic = pcall(require, "nvim-navic")
	if navic_ok and navic.is_available() then
		local ctx = navic.get_location()
		if ctx and ctx ~= "" then
			return head .. hlfmt("WinBarSep", SEP) .. ctx
		end
	end

	return head
end

function M.setup()
	local group = vim.api.nvim_create_augroup("custom_winbar", { clear = true })

	vim.api.nvim_create_autocmd({ "BufFilePost", "BufWritePost", "DirChanged" }, {
		group = group,
		callback = function()
			vim.b.winbar_prefix = nil
		end,
	})

	-- No CursorMovedI: not worth the cost on every keystroke.
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "CursorMoved", "InsertLeave" }, {
		group = group,
		callback = function()
			if vim.api.nvim_win_get_config(0).relative ~= "" then
				return
			end
			-- Don't assign "" here: it would wipe nvim-dap-view's own winbar.
			if SKIP_FT[vim.bo.filetype] or vim.bo.buftype ~= "" then
				return
			end
			vim.wo.winbar = build()
		end,
	})
end

return M
