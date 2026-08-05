-- statusline.lua
local M = {}

local SKIP_FILETYPES = {
	[""] = true,
	help = true,
	lazy = true,
	mason = true,
	minifiles = true,
	checkhealth = true,
	man = true,
	qf = true,
}

local MODE_FG_HL = {
	MiniStatuslineModeNormal = "SLModeNormalFg",
	MiniStatuslineModeInsert = "SLModeInsertFg",
	MiniStatuslineModeVisual = "SLModeVisualFg",
	MiniStatuslineModeReplace = "SLModeReplaceFg",
	MiniStatuslineModeCommand = "SLModeCommandFg",
	MiniStatuslineModeOther = "SLModeOtherFg",
}

local function set_highlights()
	for source_hl, target_hl in pairs(MODE_FG_HL) do
		local def = vim.api.nvim_get_hl(0, { name = source_hl, link = false })
		local color = def.bg or def.fg

		if color then
			vim.api.nvim_set_hl(0, target_hl, {
				fg = color,
				bold = true,
			})
		end
	end

	vim.api.nvim_set_hl(0, "SLMacro", {
		fg = "#ff5555",
		bold = true,
	})
end

set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", {
	callback = set_highlights,
})

local function with_hl(group, text)
	if not text or text == "" then
		return ""
	end

	return "%#" .. group .. "#" .. text .. "%*"
end

local function join_nonempty(parts, sep)
	local result = {}

	for _, part in ipairs(parts) do
		if part and part ~= "" then
			table.insert(result, part)
		end
	end

	return table.concat(result, sep or "")
end

local function get_diagnostics()
	local counts = vim.diagnostic.count(0)
	local severity = vim.diagnostic.severity

	local items = {
		{ severity.ERROR, "DiagnosticError", " " },
		{ severity.WARN, "DiagnosticWarn", " " },
		{ severity.INFO, "DiagnosticInfo", "󰋼 " },
		{ severity.HINT, "DiagnosticHint", "󰌵 " },
	}

	local parts = {}

	for _, item in ipairs(items) do
		local count = counts[item[1]] or 0
		if count > 0 then
			table.insert(parts, with_hl(item[2], item[3] .. count))
		end
	end

	return table.concat(parts, "  ")
end

local function get_lsp_and_formatter_status()
	if SKIP_FILETYPES[vim.bo.filetype] then
		return ""
	end

	local parts = {}

	if #vim.lsp.get_clients({ bufnr = 0 }) == 0 then
		table.insert(parts, with_hl("DiagnosticError", "󰒓 No LSP"))
	end

	local ok, conform = pcall(require, "conform")
	if ok and #conform.list_formatters(0) == 0 then
		table.insert(parts, with_hl("DiagnosticWarn", "󰒓 No fmt"))
	end

	return table.concat(parts, "  ")
end

local function get_macro_status()
	local register = vim.fn.reg_recording()

	if register == "" then
		return ""
	end

	return with_hl("SLMacro", "REC @" .. register)
end

local function get_git_branch()
	local summary = vim.b.minigit_summary

	if not summary or not summary.head_name or summary.head_name == "" then
		return ""
	end

	return with_hl("MiniStatuslineDevinfo", " " .. summary.head_name)
end

local function get_filename()
	local filename = vim.fn.expand("%:t")

	if filename == "" then
		filename = "[No Name]"
	end

	if vim.bo.modified then
		filename = filename .. " ●"
	end

	return filename
end

function M.setup()
	local statusline = require("mini.statusline")

	statusline.setup({
		use_icons = vim.g.have_nerd_font,
		content = {
			active = function()
				local _, mode_hl = statusline.section_mode({ trunc_width = 120 })
				local mode_text_hl = MODE_FG_HL[mode_hl] or "MiniStatuslineFilename"

				local filename = get_filename()
				local diagnostics = get_diagnostics()
				local lsp_status = get_lsp_and_formatter_status()
				local macro_status = get_macro_status()
				local git_branch = get_git_branch()

				local cursor = with_hl("MiniStatuslineDevinfo", "󰈙 %l:%c %p%%")

				local left = join_nonempty({
					with_hl(mode_hl, " "),
					cursor,
					with_hl(mode_text_hl, filename),
					lsp_status,
					macro_status,
				}, "  ")

				local right = join_nonempty({
					diagnostics,
					git_branch,
					with_hl(mode_hl, " "),
				}, "  ")

				return left .. "%=" .. right
			end,

			inactive = function()
				return with_hl("MiniStatuslineFilename", " " .. get_filename())
			end,
		},
	})
end

return M
