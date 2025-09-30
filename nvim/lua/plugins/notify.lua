-- Configure nvim-notify and wire it to vim.notify
-- Uses static stages per request
return {
  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    opts = {
      stages = "static",
    },
    config = function(_, opts)
      local ok, notify = pcall(require, "notify")
      if not ok then
        return
      end
      notify.setup(opts)
      vim.notify = notify
    end,
  },
}

