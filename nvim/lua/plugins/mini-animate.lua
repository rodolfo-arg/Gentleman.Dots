-- Radical smoothness: animate scroll & window changes globally
-- We keep cursor animation off to avoid conflicts with smear-cursor
return {
  "echasnovski/mini.animate",
  version = false,
  event = "VeryLazy",
  opts = function()
    local animate = require("mini.animate")

    -- Sine-based timing feels natural and smooth
    local timing = animate.gen_timing.in_out_sine({ duration = 140 })

    return {
      -- Disable cursor animation; smear-cursor handles the trail
      cursor = { enable = false },

      -- Smooth scrolling for all motions (search, { }, gg/G, zt/zz/zb, etc.)
      scroll = {
        enable = true,
        timing = timing,
        subscroll = animate.gen_subscroll.equal({ max_output_steps = 80 }),
      },

      -- Smooth resize/open/close to reduce jarring jumps in layout
      resize = {
        enable = true,
        timing = animate.gen_timing.in_out_sine({ duration = 120 }),
      },
      open = {
        enable = true,
        timing = animate.gen_timing.in_out_sine({ duration = 110 }),
      },
      close = {
        enable = true,
        timing = animate.gen_timing.in_out_sine({ duration = 110 }),
      },
    }
  end,
}

