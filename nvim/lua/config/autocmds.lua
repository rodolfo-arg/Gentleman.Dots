-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

-- Lightweight per-directory session management using builtin :mksession
-- Saves on exit; auto-restores when starting nvim in the same directory with no file args
-- Also remembers if neo-tree was open and reopens it if the session missed it
local function session_path_for_cwd()
  local state = vim.fn.stdpath("state") .. "/sessions"
  vim.fn.mkdir(state, "p")
  -- sanitize cwd into a filename
  local cwd = vim.fn.getcwd()
  local name = cwd:gsub("[/\\:]", "%%")
  return state .. "/" .. name .. ".vim"
end

local function any_win_with_ft(ft)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == ft then
      return true
    end
  end
  return false
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
    -- Allow opting out of autosave once via <leader>qd
    if vim.g.__session_stop then
      vim.g.__session_stop = nil
      return
    end
    -- Remember if neo-tree was open so we can restore it if needed
    local ok_nt = pcall(require, "neo-tree")
    if ok_nt then
      vim.g.__session_had_neotree = any_win_with_ft("neo-tree")
    else
      vim.g.__session_had_neotree = nil
    end
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
      -- If neo-tree was open but not restored, open it now
      if vim.g.__session_had_neotree then
        if not any_win_with_ft("neo-tree") then
          pcall(function()
            require("neo-tree.command").execute({ action = "show", position = "left", reveal = true })
          end)
        end
        vim.g.__session_had_neotree = nil
      end
    end)
  end,
})
