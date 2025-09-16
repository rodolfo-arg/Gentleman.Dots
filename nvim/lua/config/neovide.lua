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
  vim.g.neovide_opacity = 0.8
  vim.g.neovide_window_blurred = true

  -- Padding: keep flush to edges for faux-fullscreen effect
  vim.g.neovide_padding_top = 0
  vim.g.neovide_padding_left = 0
  vim.g.neovide_padding_right = 0
  vim.g.neovide_padding_bottom = 0

  -- After UI attaches, re-assert titlebar hidden and simulate fullscreen without macOS native fullscreen
  -- This preserves transparency/blur which macOS disables in native fullscreen spaces
  vim.api.nvim_create_autocmd("UIEnter", {
    once = true,
    callback = function()
      if not vim.g.neovide then
        return
      end
      vim.g.neovide_hide_titlebar = true
      vim.g.neovide_fullscreen = false

      -- On macOS, maximize the Neovide window to cover the screen without entering native fullscreen
      if vim.fn.has("mac") == 1 and vim.fn.executable("osascript") == 1 then
        vim.defer_fn(function()
          local script = [[
            tell application "System Events"
              if (exists application process "Neovide") then
                tell application process "Neovide"
                  set frontmost to true
                  try
                    tell application "Finder" to set screenBounds to bounds of window of desktop
                    set screenX to item 1 of screenBounds
                    set screenY to item 2 of screenBounds
                    set screenW to item 3 of screenBounds
                    set screenH to item 4 of screenBounds
                    tell window 1
                      set position to {screenX, screenY}
                      set size to {screenW, screenH}
                    end tell
                  end try
                end tell
              end if
            end tell
          ]]
          vim.fn.jobstart({ "osascript", "-e", script }, { detach = true })
        end, 150)
      end
    end,
  })

  -- Optional: keep GUI font consistent if already set elsewhere.
  -- You can customize the font via `:set guifont` or here if needed.
  -- Example (commented):
  -- vim.opt.guifont = { "IosevkaTerm Nerd Font", ":h14" }
end

return M
