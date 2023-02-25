require("mason").setup()
require("mason-lspconfig").setup {
    ensure_installed = { "lua_ls" },
}

local on_attach = function(_, _)
    -- utility
    vim.keymap.set("n", "<leader>.", vim.lsp.buf.code_action, {})
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, {silent = true})
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, {silent = true})
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, {})
    vim.keymap.set("n", "K", vim.lsp.buf.hover, {silent = true, noremap = true})

    -- errors
    vim.keymap.set("n", "<leader>l", function() vim.diagnostic.automatic() end, {})
    vim.keymap.set("n", "ge", function() vim.diagnostic.goto_next() end, {})
    vim.keymap.set("n", "gE", function() vim.diagnostic.goto_prev() end, {})
end

local capabilities = require('cmp_nvim_lsp').default_capabilities()

require("lspconfig").lua_ls.setup {
    on_attach = on_attach,
    capabilities = capabilities,
}

require("lspconfig").omnisharp.setup {
    on_attach = on_attach,
    capabilities = capabilities,
}
