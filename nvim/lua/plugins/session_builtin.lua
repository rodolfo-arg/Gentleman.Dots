return {
  {
    "gentleman/session-builtin",
    -- Register session autocmds as early as possible
    init = function()
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

      -- Align sessionoptions to capture layout and local state
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
          if vim.g.__session_stop then
            vim.g.__session_stop = nil
            return
          end
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
            -- Hide Snacks dashboard if present
            pcall(function()
              local ok_snacks, snacks = pcall(require, "snacks")
              if ok_snacks and snacks.dashboard then snacks.dashboard.hide() end
            end)
            -- Close intrusive news/changelog buffers
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
            close_news_windows()
            local session = session_path_for_cwd()
            if vim.fn.filereadable(session) == 1 then
              pcall(vim.cmd, "silent! source " .. vim.fn.fnameescape(session))
            end
            if vim.g.__session_had_neotree then
              if not any_win_with_ft("neo-tree") then
                pcall(function()
                  require("neo-tree.command").execute({ action = "show", position = "left", reveal = true })
                end)
              end
              vim.g.__session_had_neotree = nil
            end
            vim.defer_fn(close_news_windows, 200)
          end)
        end,
      })
    end,
  },
}

