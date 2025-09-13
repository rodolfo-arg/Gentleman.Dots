-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Lightweight per-directory session management using builtin :mksession
-- Saves on exit; auto-restores when starting nvim in the same directory with no file args
local function session_path_for_cwd()
  local state = vim.fn.stdpath("state") .. "/sessions"
  vim.fn.mkdir(state, "p")
  -- sanitize cwd into a filename
  local cwd = vim.fn.getcwd()
  local name = cwd:gsub("[/\\:]", "%%")
  return state .. "/" .. name .. ".vim"
end

vim.opt.sessionoptions = {
  "buffers",
  "curdir",
  "tabpages",
  "winsize",
  "help",
  "globals",
  "folds",
  "localoptions",
  "options",
}

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    local session = session_path_for_cwd()
    pcall(vim.cmd, "silent! mksession! " .. vim.fn.fnameescape(session))
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    if vim.fn.argc() ~= 0 then return end
    -- Defer to let lazy.nvim settle
    vim.schedule(function()
      -- hide Snacks dashboard if present
      pcall(function()
        local ok_snacks, snacks = pcall(require, "snacks")
        if ok_snacks and snacks.dashboard then snacks.dashboard.hide() end
      end)
      local session = session_path_for_cwd()
      if vim.fn.filereadable(session) == 1 then
        pcall(vim.cmd, "silent! source " .. vim.fn.fnameescape(session))
      end
    end)
  end,
})
