-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.api.nvim_create_autocmd("FileType", {
  pattern = "cpp",
  callback = function()
    vim.b.autoformat = false
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*",
  callback = function()
    -- Always start in insert mode
    vim.cmd("startinsert")

    -- Make sure <C-w> works in terminal normal mode
    vim.keymap.set("n", "<C-w>h", "<C-w>h", { buffer = true })
    vim.keymap.set("n", "<C-w>j", "<C-w>j", { buffer = true })
    vim.keymap.set("n", "<C-w>k", "<C-w>k", { buffer = true })
    vim.keymap.set("n", "<C-w>l", "<C-w>l", { buffer = true })

    -- Seamless movement from terminal insert mode
    vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], { buffer = true })
    vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], { buffer = true })
    vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], { buffer = true })
    vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], { buffer = true })
  end,
})
