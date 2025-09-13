return {
  {
    "folke/snacks.nvim",
    priority = 10000,
    opts = function(_, opts)
      opts = opts or {}
      opts.dashboard = opts.dashboard or {}
      opts.dashboard.enabled = true
      return opts
    end,
  },
}

