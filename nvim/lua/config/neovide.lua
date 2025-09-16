-- Neovide-specific configuration (animations only)
-- Applies only when running inside Neovide GUI

local M = {}

function M.setup()
  -- Guard: only apply when Neovide is present
  if not vim.g.neovide then
    return
  end

  -- Animations: snappy baseline
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

  -- Optional: keep GUI font consistent if already set elsewhere.
  -- You can customize the font via `:set guifont` or here if needed.
  -- Example (commented):
  -- vim.opt.guifont = { "IosevkaTerm Nerd Font", ":h14" }
end

return M
