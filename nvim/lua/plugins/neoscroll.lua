-- Smooth scrolling to reduce viewport jank when moving beyond visible range
return {
  "karb94/neoscroll.nvim",
  event = "VeryLazy",
  opts = {
    -- Animate common scroll and recenter actions
    mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
    hide_cursor = false,       -- keep cursor visible for smear effect
    stop_eof = true,
    respect_scrolloff = true,  -- respect our scrolloff when animating
    use_local_scrolloff = true,
    performance_mode = true,
    easing_function = "sine", -- even smoother than quadratic
  },
}
