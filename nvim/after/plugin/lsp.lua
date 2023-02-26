local lsp = require('lsp-zero').preset({
    name = 'minimal',
    set_lsp_keymaps = true,
    manage_nvim_cmp = true,
    suggest_lsp_servers = false,
})

-- (Optional) Configure lua language server for neovim
lsp.nvim_workspace()

lsp.ensure_installed({
    "lua_ls",
    -- C#
    "omnisharp",
    -- TypeScript
    "tsserver",
    "angularls",
    "astro",
    -- HTML & CSS
    "html",
    "cssls",
    "emmet_ls",
    -- Docker
    "dockerls",
    "docker_compose_language_service",
})

lsp.setup()

local cmp = require('cmp')
local cmp_select = { behavior = cmp.SelectBehavior.Select }
local cmp_mappings = lsp.defaults.cmp_mappings({
    ['<s-TAB>'] = cmp.mapping.select_prev_item(cmp_select),
    ['<TAB>'] = cmp.mapping.select_next_item(cmp_select),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<C-Space>'] = cmp.mapping.complete(),
})
-- local cmp_formatting = lsp.defaults.cmp_formatting({
--     format = require('lspkind').cmp_format({
--         mode = "symbol"
--     })
-- })

lsp.set_preferences({
    -- sign_icons = {}
})

lsp.on_attach(function(client, bufnr)
    local opts = { buffer = bufnr, remap = false }
    -- utility
    vim.keymap.set("n", "<leader>.", vim.lsp.buf.code_action, opts)
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

    -- errors
    vim.keymap.set("n", "ge", function() vim.diagnostic.goto_next() end, opts)
    vim.keymap.set("n", "gE", function() vim.diagnostic.goto_prev() end, opts)

    -- format
    vim.keymap.set("n", "<leader>l", function() vim.lsp.buf.format() end, opts)
end)
