return {
  {
    "folke/snacks.nvim",
    init = function()
      local function session_path_for_cwd()
        local state = vim.fn.stdpath("state") .. "/sessions"
        local cwd = vim.fn.getcwd()
        local name = cwd:gsub("[/\\:]", "%%")
        return state .. "/" .. name .. ".vim"
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        callback = function()
          local argc = vim.fn.argc()
          local allow = (argc == 0) or (argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1)
          if not allow then return end

          local session = session_path_for_cwd()
          if vim.fn.filereadable(session) ~= 1 then
            -- No session: ensure snacks is loaded and show dashboard
            pcall(function()
              local ok_lazy, lazy = pcall(require, "lazy")
              if ok_lazy and lazy and lazy.load then
                pcall(lazy.load, { plugins = { "snacks.nvim" } })
              end
              local ok, snacks = pcall(require, "snacks")
              if ok and snacks.dashboard and snacks.dashboard.show then
                snacks.dashboard.show()
              end
            end)
          end
        end,
      })
    end,
  },
}

