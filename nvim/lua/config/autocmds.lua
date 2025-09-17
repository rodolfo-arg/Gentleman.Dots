-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Session management is registered early in config/sessions.lua

-- Keep buffers synced with on-disk changes and avoid noisy prompts
do
  local group = vim.api.nvim_create_augroup("file_sync", { clear = true })

  -- Proactively check for external changes when focusing Neovim or moving around
  vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave", "BufEnter", "CursorHold", "CursorHoldI" }, {
    group = group,
    callback = function()
      -- Don't disrupt command-line mode
      local mode = vim.api.nvim_get_mode().mode
      if mode ~= "c" then
        pcall(vim.cmd.checktime)
      end
    end,
  })

  -- Notify when a file was reloaded due to external changes
  vim.api.nvim_create_autocmd("FileChangedShellPost", {
    group = group,
    callback = function()
      vim.notify("File changed on disk. Buffer reloaded.", vim.log.levels.INFO)
    end,
  })

  -- If a swap file is detected, just edit anyway (no prompt)
  vim.api.nvim_create_autocmd("SwapExists", {
    group = group,
    callback = function()
      vim.v.swapchoice = "e"
    end,
  })
end
