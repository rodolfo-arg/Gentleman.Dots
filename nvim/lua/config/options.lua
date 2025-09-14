-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Keep the cursor away from window edges to reduce jank
vim.o.scrolloff = 8
vim.o.sidescrolloff = 8

-- Make UI steadier and cut layout jitter
vim.o.signcolumn = "yes:2"      -- reserve space for diagnostics/gitsigns
vim.o.updatetime = 150           -- snappier CursorHold/diagnostics without being too chatty
vim.o.redrawtime = 10000         -- allow longer redraws before timing out
vim.o.lazyredraw = true          -- reduce intermediate redraws during macros/large ops
vim.o.synmaxcol = 240            -- stop syntax on very long lines (reduces jank on minified files)
vim.o.termguicolors = true       -- ensure truecolor for smooth rendering

vim.api.nvim_create_autocmd("FileType", {
  pattern = "cpp",
  callback = function()
    vim.b.autoformat = false
  end,
})

-- Smart cursorline: show only in active window and outside insert mode
vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
  callback = function()
    vim.wo.cursorline = false
  end,
})

vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
  callback = function()
    vim.wo.cursorline = true
  end,
})

-- Large file guard: lighten features on very big files
vim.api.nvim_create_autocmd("BufReadPre", {
  callback = function(args)
    local name = vim.api.nvim_buf_get_name(args.buf)
    if name == "" then return end
    local ok, stat = pcall(vim.loop.fs_stat, name)
    if not ok or not stat then return end
    if stat.size and stat.size > 1.5 * 1024 * 1024 then
      vim.b.large_buf = true
      -- Disable Treesitter highlighting if available
      local ok_ts, ts = pcall(require, "vim.treesitter")
      if ok_ts and ts then pcall(ts.stop, args.buf) end
      -- Keep formatting and heavy background tasks off for large files
      vim.b.autoformat = false
      -- Use simpler folding to avoid expensive calculations
      vim.wo.foldmethod = "manual"
    end
  end,
})

-- Diagnostics: avoid updates while typing to reduce flicker
pcall(vim.diagnostic.config, {
  update_in_insert = false,
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
