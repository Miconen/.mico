-- plugins/treesitter.lua

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    cmd = {
      "TSBufDisable", "TSBufEnable", "TSBufToggle",
      "TSDisable", "TSEnable", "TSToggle",
      "TSInstall", "TSInstallInfo", "TSInstallSync",
      "TSModuleInfo", "TSUninstall", "TSUpdate", "TSUpdateSync",
    },
    main = "nvim-treesitter.configs",
    opts = {
      ensure_installed = {
        "bash", "c", "diff", "html",
        "lua", "luadoc",
        "markdown", "markdown_inline",
        "query", "vim", "vimdoc",
        -- Your languages
        "go", "gomod", "gowork", "gosum",
        "typescript", "javascript", "tsx",
        "python",
        "json", "jsonc", "yaml", "toml",
        "css", "scss",
        "sql",
        "dockerfile",
        "gitcommit", "gitignore",
      },
      auto_install = true,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = { "ruby" },
      },
      indent = {
        enable  = true,
        disable = { "ruby" },
      },
    },
  },
}
