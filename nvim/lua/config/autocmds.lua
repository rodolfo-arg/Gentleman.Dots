-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Session management is registered early in config/sessions.lua

-- Auto-yank visual selections to the system clipboard on mouse/visual release
-- This mimics tmux's "copy on select" feel inside Neovim.
-- It reselects the last visual selection (gv) and yanks to +, then returns to normal mode,
-- which clears the highlight so it "feels" like something happened.
local group = vim.api.nvim_create_augroup("AutoYankOnVisual", { clear = true })
vim.api.nvim_create_autocmd("ModeChanged", {
  group = group,
  pattern = "[vV\x16]:n",
  callback = function()
    -- schedule to run after mode change completes to avoid recursion
    vim.schedule(function()
      pcall(vim.cmd, [[silent normal! gv"+y]])
    end)
  end,
  desc = "Yank visual selection to system clipboard on visual exit",
})

