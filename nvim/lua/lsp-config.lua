-- Array of lsps to initialize
local lsps = {
    -- Lua
    [1] = "lua_ls",
    -- C#
    [2] = "omnisharp",
    -- TypeScript
    [3] = "tsserver",
    [4] = "angularls",
    [5] = "astro",
    -- HTML & CSS
    [6] = "html",
    [7] = "cssls",
    [8] = "emmet_ls",
}

-- Mason setup
require("mason").setup()
require("mason-lspconfig").setup {
    ensure_installed = lsps
}

-- Keybinds
local on_attach = function(_, _)
    -- utility
    vim.keymap.set("n", "<leader>.", vim.lsp.buf.code_action, {})
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { silent = true })
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { silent = true })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { silent = true, noremap = true })

    -- errors
    vim.keymap.set("n", "ge", function() vim.diagnostic.goto_next() end, {})
    vim.keymap.set("n", "gE", function() vim.diagnostic.goto_prev() end, {})

    -- format
    vim.keymap.set("n", "<leader>l", function() vim.lsp.buf.format() end, {})
end

-- Autocompletion
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Initialize language servers from lsps array
for _, lsp in ipairs(lsps) do
    require("lspconfig")[lsp].setup {
        on_attach = on_attach,
        capabilities = capabilities,
    }
end
