return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      -- Ensure fish uses fish_indent and not trying to execute the script
      opts.formatters_by_ft.fish = { "fish_indent" }
      return opts
    end,
  },
}

