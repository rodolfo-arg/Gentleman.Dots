return {
  "sphamba/smear-cursor.nvim",
  opts = {
    -- Make the trail more elastic/springy vs. rigid
    stiffness = 0.7,      -- lower = softer, higher = stiffer
    -- Update more frequently for smoother motion
    interval = 8,         -- ms between updates
  },
}
