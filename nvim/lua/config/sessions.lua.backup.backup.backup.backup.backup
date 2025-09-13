-- Early session management using builtin :mksession
-- - Saves per-directory session on exit (VimLeavePre)
-- - Loads session after VeryLazy (plugins ready) when opened with no file args or with a single dir arg
-- - Hides dashboards/news that could clobber layout when restoring
-- - Reopens neo-tree if it was open but not serialized (via a persisted marker)

local M = {}

local function session_path_for_cwd()
  local state = vim.fn.stdpath("state") .. "/sessions"
  vim.fn.mkdir(state, "p")
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

local function close_news_windows()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      local ft = vim.bo[buf].filetype
      if ft == "snacks_news" or name:match("NEWS%.md$") or name:lower():match("changelog") then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end
end

local function close_browser_windows()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(buf) then
      local ft = vim.bo[buf].filetype
      if ft == "netrw" or ft == "oil" or ft == "neo-tree" or ft == "minifiles" then
        pcall(vim.api.nvim_win_close, win, true)
      end
    end
  end
end

function M.setup()
  -- Ensure desired sessionoptions from the start
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

  -- Save on exit and persist whether neo-tree was open as a marker file
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if vim.g.__session_stop then
        vim.g.__session_stop = nil
        return
      end
      local had_neotree = any_win_with_ft("neo-tree")
      local session = session_path_for_cwd()
      pcall(vim.cmd, "silent! mksession! " .. vim.fn.fnameescape(session))
      local marker = session .. ".neotree"
      if had_neotree then
        pcall(vim.fn.writefile, { "" }, marker)
      else
        pcall(vim.fn.delete, marker)
      end
    end,
  })

  -- Load after VeryLazy so UI/plugins are ready and won't clobber layout
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      local argc = vim.fn.argc()
      local allow = false
      if argc == 0 then
        allow = true
      elseif argc == 1 then
        local a0 = vim.fn.argv(0)
        if vim.fn.isdirectory(a0) == 1 then
          allow = true
        end
      end
      if not allow then return end

      -- Slightly defer to let other VeryLazy handlers settle first
      vim.defer_fn(function()
        close_news_windows()
        local session = session_path_for_cwd()
        local has_session = (vim.fn.filereadable(session) == 1)
        if has_session then
          -- Hide dashboard and close intrusive buffers that may claim layout
          pcall(function()
            local ok_snacks, snacks = pcall(require, "snacks")
            if ok_snacks and snacks.dashboard then snacks.dashboard.hide() end
          end)
          close_browser_windows()
          -- Source the session
          pcall(vim.cmd, "silent! source " .. vim.fn.fnameescape(session))
          -- Restore neo-tree if it was open before exit
          local marker = session .. ".neotree"
          if vim.fn.filereadable(marker) == 1 and not any_win_with_ft("neo-tree") then
            pcall(function()
              require("neo-tree.command").execute({ action = "show", position = "left" })
            end)
          end
          pcall(vim.fn.delete, marker)
        else
          -- No session: explicitly ensure Snacks is loaded and show the dashboard
          pcall(function()
            local ok_lazy, lazy = pcall(require, "lazy")
            if ok_lazy and lazy and lazy.load then
              pcall(lazy.load, { plugins = { "snacks.nvim" } })
            end
            local ok_snacks, snacks = pcall(require, "snacks")
            if ok_snacks and snacks.dashboard and snacks.dashboard.show then snacks.dashboard.show() end
          end)
        end
        -- Final sweep in case something opened late
        vim.defer_fn(function()
          close_news_windows()
        end, 150)
      end, 150)
    end,
  })

  -- User commands for convenience (for users typing :QS instead of <leader>qs)
  local function session_path()
    return session_path_for_cwd()
  end
  vim.api.nvim_create_user_command("SessionSave", function()
    local ok, err = pcall(vim.cmd, "silent! mksession! " .. vim.fn.fnameescape(session_path()))
    if ok then vim.notify("Session saved") else vim.notify("Session save failed: " .. tostring(err), vim.log.levels.ERROR) end
  end, {})
  vim.api.nvim_create_user_command("SessionLoad", function()
    local path = session_path()
    if vim.fn.filereadable(path) == 1 then
      local ok, err = pcall(vim.cmd, "silent! source " .. vim.fn.fnameescape(path))
      if ok then vim.notify("Session loaded") else vim.notify("Session load failed: " .. tostring(err), vim.log.levels.ERROR) end
    else
      vim.notify("No session for this directory", vim.log.levels.WARN)
    end
  end, {})
  vim.api.nvim_create_user_command("SessionStop", function()
    vim.g.__session_stop = true
    vim.notify("Session autosave disabled for this exit")
  end, {})
  -- Short aliases
  vim.api.nvim_create_user_command("QS", function() vim.cmd("SessionSave") end, {})
  vim.api.nvim_create_user_command("QL", function() vim.cmd("SessionLoad") end, {})
  vim.api.nvim_create_user_command("QD", function() vim.cmd("SessionStop") end, {})
end

return M

