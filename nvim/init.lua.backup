require("config.nodejs").setup({ silent = true })

-- Register session autocmds early (before Lazy & VimEnter)
pcall(function()
  require("config.sessions").setup()
end)

-- Apply Neovide tweaks when running in Neovide (no-op otherwise)
pcall(function()
  require("config.neovide").setup()
end)

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
vim.opt.timeoutlen = 1000
vim.opt.ttimeoutlen = 0
