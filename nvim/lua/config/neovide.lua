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

  -- UI: remove title bar and enable transparency/blur
  vim.g.neovide_hide_titlebar = true
  -- neovide_transparency is deprecated; use neovide_opacity (lower is more transparent)
  vim.g.neovide_opacity = 0.85
  vim.g.neovide_window_blurred = true

  -- Optional: small padding to avoid traffic-lights overlap on macOS when titlebar hidden
  vim.g.neovide_padding_top = 6
  vim.g.neovide_padding_left = 6
  vim.g.neovide_padding_right = 6
  vim.g.neovide_padding_bottom = 6

  -- Try to force titlebar removal/fullscreen after UI is ready (workaround older builds)
  vim.api.nvim_create_autocmd("UIEnter", {
    once = true,
    callback = function()
      if vim.g.neovide then
        vim.g.neovide_hide_titlebar = true
        -- Open directly in fullscreen as a reliable way to avoid title bar
        vim.g.neovide_fullscreen = true
      end
    end,
  })

  -- Optional: keep GUI font consistent if already set elsewhere.
  -- You can customize the font via `:set guifont` or here if needed.
  -- Example (commented):
  -- vim.opt.guifont = { "IosevkaTerm Nerd Font", ":h14" }
end

return M
