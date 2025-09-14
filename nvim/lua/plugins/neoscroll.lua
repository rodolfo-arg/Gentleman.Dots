-- Smooth scrolling without conflicting animations
return {
  "karb94/neoscroll.nvim",
  event = "VeryLazy",
  opts = {
    mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>", "<C-y>", "<C-e>", "zt", "zz", "zb" },
    hide_cursor = false,
    stop_eof = true,
    respect_scrolloff = true,
    use_local_scrolloff = true,
    performance_mode = true,
    easing_function = "sine",
  },
}

