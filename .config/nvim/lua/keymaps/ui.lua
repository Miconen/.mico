-- keymaps/ui.lua
local wk = require("which-key")
local map = vim.keymap.set
wk.add({
	{ "<leader>u", group = " UI" },
})

-- ── Snacks toggles ───────────────────────────────────────────────────────────
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

map("n", "<leader>un", function()
	Snacks.notifier.show_history()
end, { desc = "Notification history" })

-- ── Package managers ─────────────────────────────────────────────────────────
wk.add({ { "<leader>p", group = "󰏖 Packages" } })

map("n", "<leader>pl", function()
	require("lazy").show()
end, { desc = "Lazy" })
map("n", "<leader>pL", function()
	require("lazy").update()
end, { desc = "Lazy update" })
map("n", "<leader>pm", "<cmd>Mason<cr>", { desc = "Mason" })
map("n", "<leader>pM", "<cmd>MasonUpdate<cr>", { desc = "Mason update" })
map("n", "<leader>pt", "<cmd>TSInstallInfo<cr>", { desc = "Treesitter info" })
map("n", "<leader>pT", "<cmd>TSUpdate<cr>", { desc = "Treesitter update" })
