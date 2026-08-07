-- keymaps/ui.lua
local wk = require("which-key")
local map = vim.keymap.set
local icons = require("keymaps.icons")

wk.add({
	{ "<leader>u", group = icons.UI .. " UI" },
	{ "<leader>p", group = icons.Package .. " Packages" },
})

Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
Snacks.toggle.option("relativenumber", { name = "Relative number" }):map("<leader>uL")
Snacks.toggle
	.option("conceallevel", {
		name = "Conceal",
		off = 0,
		on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2,
	})
	:map("<leader>uc")
Snacks.toggle.diagnostics():map("<leader>ud")
Snacks.toggle.line_number():map("<leader>ul")
Snacks.toggle.treesitter():map("<leader>uT")
Snacks.toggle.inlay_hints():map("<leader>uh")
Snacks.toggle.dim():map("<leader>uz")

-- Only meaningful in markdown buffers; harmless elsewhere. render-markdown is
-- lazy-loaded on the markdown filetype, hence the require inside the callback.
Snacks.toggle
	.new({
		name = "Markdown render",
		get = function()
			local ok, rm = pcall(require, "render-markdown")
			return ok and rm.get() or false
		end,
		set = function()
			local ok, rm = pcall(require, "render-markdown")
			if ok then
				rm.toggle()
			end
		end,
	})
	:map("<leader>um")

map("n", "<leader>un", function()
	Snacks.notifier.show_history()
end, { desc = "Notification history" })

map("n", "<leader>pl", function()
	require("lazy").show()
end, { desc = "Lazy" })
map("n", "<leader>pL", function()
	require("lazy").update()
end, { desc = "Lazy update" })
map("n", "<leader>pm", "<cmd>Mason<cr>", { desc = "Mason" })
map("n", "<leader>pM", "<cmd>MasonUpdate<cr>", { desc = "Mason update" })
map("n", "<leader>pt", "<cmd>TSLog<cr>", { desc = "Treesitter log" })
map("n", "<leader>pT", "<cmd>TSUpdate<cr>", { desc = "Treesitter update" })
