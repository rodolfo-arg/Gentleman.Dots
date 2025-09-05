return {
  "folke/snacks.nvim",
  opts = {
    indent = {
      enabled = true, -- keep indent guides
      scope = { enabled = false }, -- optional: disable scope highlighting (less buggy)
    },
  },
  config = function(_, opts)
    local ok, snacks = pcall(require, "snacks")
    if not ok then
      return
    end

    -- Load indent safely
    local indent_ok, indent = pcall(require, "snacks.indent")
    if indent_ok then
      local old_step = indent.step
      indent.step = function(...)
        local success, result = pcall(old_step, ...)
        if not success then
          vim.schedule(function()
            vim.notify("Snacks indent error suppressed", vim.log.levels.DEBUG)
          end)
        end
        return result
      end
    end

    snacks.setup(opts)
  end,
}
