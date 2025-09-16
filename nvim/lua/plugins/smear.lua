return {
  "sphamba/smear-cursor.nvim",
  -- Disable in Neovide to avoid visual/position glitches with GUI rendering
  enabled = function()
    return not vim.g.neovide
  end,
  opts = {
    stiffness = 0.9,
    trailing_stiffness = 0.5,
    distance_stop_animating = 0.1,
  },
}
