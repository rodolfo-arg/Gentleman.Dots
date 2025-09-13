return {
  -- Per-directory sessions: auto-save on exit, auto-restore on start
  "folke/persistence.nvim",
  event = "VeryLazy",
  opts = {
    -- Save enough state to restore layout, windows, help, globals
    options = { "buffers", "curdir", "tabpages", "winsize", "help", "globals" },
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

    -- Auto-save session on exit
    vim.api.nvim_create_autocmd("VimLeavePre", {
      callback = function()
        pcall(persistence.save)
      end,
    })

    -- Auto-load session for current directory on startup when no file args
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        if vim.fn.argc() == 0 then
          pcall(persistence.load)
          vim.g.session_loaded = true
        end
      end,
    })
  end,
  keys = {
    { "<leader>qs", function() require("persistence").save() end, desc = "Session Save" },
    { "<leader>ql", function() require("persistence").load() end, desc = "Session Load (cwd)" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Session Stop (no save)" },
  },
}

