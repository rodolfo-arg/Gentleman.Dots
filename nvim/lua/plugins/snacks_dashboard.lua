return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts = opts or {}
      opts.dashboard = opts.dashboard or {}
      opts.dashboard.enabled = true
      return opts
    end,
  },
}

