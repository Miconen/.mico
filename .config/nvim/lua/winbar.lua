-- winbar.lua
-- Breadcrumb: 󰉋 cwd › 󰉋 folder › [lang icon] file › [symbol type] symbol name

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
}

local FOLDER = "󰉋 "
local SEP = " › "

local function set_hls()
	vim.api.nvim_set_hl(0, "WinBarSep", { link = "NonText" }) -- subtle › separators
	vim.api.nvim_set_hl(0, "WinBarDir", { link = "Directory" }) -- blue folders
	vim.api.nvim_set_hl(0, "WinBarFile", { link = "Normal" }) -- filename
	vim.api.nvim_set_hl(0, "NavicSeparator", { link = "NonText" }) -- navic › matches ours
end
set_hls()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_hls })

local function hlfmt(group, text)
	return "%#" .. group .. "#" .. text .. "%*"
end

local function build()
	if SKIP_FT[vim.bo.filetype] or vim.bo.buftype ~= "" then
		return ""
	end

	local fullpath = vim.fn.expand("%:p")
	if fullpath == "" then
		return ""
	end

	local cwd_name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	local relative = vim.fn.fnamemodify(fullpath, ":.")
	local filename = vim.fn.fnamemodify(fullpath, ":t")
	local rel_dir = vim.fn.fnamemodify(relative, ":h")

	-- Filetype icon + its own highlight color (e.g. blue for Go, green for Lua)
	local file_icon = ""
	local file_icon_hl = "WinBarFile"
	local icons_ok, icons = pcall(require, "mini.icons")
	if icons_ok then
		local icon, icon_hl = icons.get("file", filename)
		file_icon = icon .. " "
		file_icon_hl = icon_hl
	end

	local parts = {}

	-- CWD root
	table.insert(parts, hlfmt("WinBarDir", FOLDER .. cwd_name))

	-- Intermediate directories (skip when file is directly in cwd)
	if rel_dir ~= "." and rel_dir ~= "" then
		for seg in rel_dir:gmatch("[^/\\]+") do
			table.insert(parts, hlfmt("WinBarSep", SEP))
			table.insert(parts, hlfmt("WinBarDir", FOLDER .. seg))
		end
	end

	-- Filename with language-colored icon
	table.insert(parts, hlfmt("WinBarSep", SEP))
	table.insert(parts, hlfmt(file_icon_hl, file_icon) .. hlfmt("WinBarFile", filename))

	-- LSP symbol context: › [symbol type icon] symbol name  (only when inside a block)
	local navic_ok, navic = pcall(require, "nvim-navic")
	if navic_ok and navic.is_available() then
		local ctx = navic.get_location()
		if ctx and ctx ~= "" then
			table.insert(parts, hlfmt("WinBarSep", SEP))
			table.insert(parts, ctx) -- navic handles its own per-kind icons + highlights
		end
	end

	return " " .. table.concat(parts)
end

function M.setup()
	local group = vim.api.nvim_create_augroup("custom_winbar", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "CursorMoved", "CursorMovedI", "InsertLeave" }, {
		group = group,
		callback = function()
			-- Skip floating windows (pickers, hovers, etc.)
			if vim.api.nvim_win_get_config(0).relative == "" then
				vim.wo.winbar = build()
			end
		end,
	})
end

return M
