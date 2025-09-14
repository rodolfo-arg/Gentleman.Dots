-- Smooth, comprehensive scrolling and subtle UI animations.
-- Cursor animation is disabled to avoid conflicts with smear-cursor.
return {
  "echasnovski/mini.animate",
  version = false,
  event = "VeryLazy",
  opts = function()
    local animate = require("mini.animate")

    -- Natural, gentle easing
    local timing = animate.gen_timing.in_out_sine({ duration = 150 })

    return {
      cursor = { enable = false }, -- smear-cursor handles cursor feel

      -- Smooth scrolling for motions (search, { }, gg/G, zt/zz/zb, etc.)
      scroll = {
        enable = true,
        timing = timing,
        subscroll = animate.gen_subscroll.equal({ max_output_steps = 80 }),
      },

      -- Subtle window animations to reduce jarring layout changes
      resize = { enable = true, timing = animate.gen_timing.in_out_sine({ duration = 120 }) },
      open   = { enable = true, timing = animate.gen_timing.in_out_sine({ duration = 110 }) },
      close  = { enable = true, timing = animate.gen_timing.in_out_sine({ duration = 110 }) },
    }
  end,
}

