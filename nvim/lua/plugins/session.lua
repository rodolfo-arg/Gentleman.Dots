return {
  -- Per-directory sessions: auto-save on exit, auto-restore on start
  "folke/persistence.nvim",
  -- Register autocommands early so VimEnter hook always runs
  init = function()
    local function any_win_with_ft(ft)
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == ft then
          return true
        end
      end
      return false
    end
    -- Auto-save session on exit
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        -- Remember if neo-tree was open to restore explicitly if session misses it
        local ok_nt, _ = pcall(require, "neo-tree")
        if ok_nt then
          vim.g.__session_had_neotree = any_win_with_ft("neo-tree")
        else
          vim.g.__session_had_neotree = nil
        end
        local ok, persistence = pcall(require, "persistence")
        if ok then pcall(persistence.save) end
      end,
    })

    -- Auto-load session for current directory on startup when no file args
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        if vim.fn.argc() ~= 0 then return end
        -- Hide Snacks dashboard if present to avoid conflicts
        pcall(function()
          local ok_snacks, snacks = pcall(require, "snacks")
          if ok_snacks and snacks.dashboard then snacks.dashboard.hide() end
        end)
        local ok, persistence = pcall(require, "persistence")
        if ok then pcall(persistence.load) end
        -- If neo-tree was open but not restored, open it now
        if vim.g.__session_had_neotree then
          if not any_win_with_ft("neo-tree") then
            pcall(function()
              require("neo-tree.command").execute({ action = "show", position = "left", reveal = true })
            end)
          end
          vim.g.__session_had_neotree = nil
        end
        vim.g.session_loaded = true
      end,
    })
  end,
  opts = {
    -- Save enough state to restore layout, windows, help, globals
    options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals", "folds", "localoptions", "options" },
  },
  config = function(_, opts)
    local ok, persistence = pcall(require, "persistence")
    if not ok then
      return
    end
    -- Ensure sessionoptions aligns with what we save
    vim.opt.sessionoptions = {
      "buffers",
      "curdir",
      "tabpages",
      "winsize",
      "help",
      "globals",
    }
    persistence.setup(opts)

  end,
  keys = {
    { "<leader>qs", function() require("persistence").save() end, desc = "Session Save" },
    { "<leader>ql", function() require("persistence").load() end, desc = "Session Load (cwd)" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Session Stop (no save)" },
  },
}
