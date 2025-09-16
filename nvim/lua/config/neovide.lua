-- Neovide-specific configuration
-- Applies only when running inside Neovide GUI

local M = {}

function M.setup()
  -- Guard: only apply when Neovide is present
  if not vim.g.neovide then
    return
  end

  -- Animations: revert speed to previous snappy baseline, keep fixes on
  -- Keep position animation disabled to avoid resize/neo-tree jitter
  vim.g.neovide_position_animation_length = 0

  -- Cursor animations (previous values)
  vim.g.neovide_cursor_animation_length = 0.025
  vim.g.neovide_cursor_trail_size = 0.15
  vim.g.neovide_cursor_animate_in_insert_mode = true
  vim.g.neovide_cursor_animate_command_line = true

  -- Scrolling animations (previous values)
  vim.g.neovide_scroll_animation_length = 0.05
  vim.g.neovide_scroll_animation_far_lines = 10

  -- Rendering tweaks to minimize visual glitches
  vim.g.neovide_no_idle = true
  vim.g.neovide_refresh_rate = 120
  vim.g.neovide_refresh_rate_idle = 60
  vim.g.neovide_hide_mouse_when_typing = true
  vim.g.neovide_remember_window_size = true

  -- UI: remove title bar and enable transparency
  vim.g.neovide_hide_titlebar = true
  vim.g.neovide_transparency = 0.9

  -- Optional: keep GUI font consistent if already set elsewhere.
  -- You can customize the font via `:set guifont` or here if needed.
  -- Example (commented):
  -- vim.opt.guifont = { "IosevkaTerm Nerd Font", ":h14" }
end

return M
