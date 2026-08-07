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

-- render-markdown and csvview are both lazy-loaded, so their state getters must
-- not require them. Snacks' which-key integration calls get() when the <leader>u
-- menu is drawn, and a require there would load the plugin just for browsing the
-- menu. package.loaded is the honest answer: not loaded means not rendering.
--
-- set() takes the state Snacks computed rather than calling the plugin's own
-- toggle(), so the two cannot disagree about which way to flip.
Snacks.toggle
	.new({
		name = "Markdown render",
		get = function()
			local rm = package.loaded["render-markdown"]
			return rm ~= nil and rm.get()
		end,
		set = function(state)
			local rm = require("render-markdown")
			if state then
				rm.enable()
			else
				rm.disable()
			end
		end,
	})
	:map("<leader>um")

Snacks.toggle
	.new({
		name = "CSV view",
		get = function()
			local cv = package.loaded["csvview"]
			-- 0 resolves to the current buffer; the view is per buffer.
			return cv ~= nil and cv.is_enabled(0)
		end,
		set = function(state)
			local cv = require("csvview")
			if state then
				cv.enable(0)
			else
				cv.disable(0)
			end
		end,
	})
	:map("<leader>uC")

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
