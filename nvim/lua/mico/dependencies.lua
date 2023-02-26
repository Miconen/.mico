vim.notify = require("notify")

if vim.fn.executable('rg') ~= 1 then
    vim.notify("Couldn't find the command: rg (ripgrep)\nSome Telescope functionality might not work.", "warn", {
        title = "Missing dependency",
    })
end
