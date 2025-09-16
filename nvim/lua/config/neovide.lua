-- Neovide-specific configuration (animations only)
-- Applies only when running inside Neovide GUI

local M = {}

function M.setup()
  -- Guard: only apply when Neovide is present
  if not vim.g.neovide then
    return
  end

  -- Detect platform (macOS) for Cmd key mappings
  local is_macos = (vim.loop.os_uname().sysname == "Darwin")

  -- Animations: snappy baseline
  -- Keep position animation disabled to avoid resize/neo-tree jitter
  vim.g.neovide_position_animation_length = 0

  -- Cursor animations (previous values)
  vim.g.neovide_cursor_animation_length = 0.09
  vim.g.neovide_cursor_trail_size = 0.15
  vim.g.neovide_cursor_animate_in_insert_mode = true
  vim.g.neovide_cursor_animate_command_line = true
  vim.g.neovide_curser_antialiasing = true
  vim.g.neovide_cursor_smooth_blink = true
  vim.g.neovide_cursor_vfx_mode = "pixiedust"
  vim.g.neovide_remember_window_size = true
  vim.g.neovide_profiler = true

  -- Scrolling animations (previous values)
  vim.g.neovide_scroll_animation_length = 0.05
  vim.g.neovide_scroll_animation_far_lines = 10

  -- Optional: keep GUI font consistent if already set elsewhere.
  -- You can customize the font via `:set guifont` or here if needed.
  -- Example (commented):
  vim.opt.guifont = { "Zed Mono", ":h14" }
  vim.g.neovide_opacity = 0.0
  vim.g.transparency = 0.2
  vim.g.neovide_background_color = "#0f1117" .. alpha()

  -- Clipboard: enable Cmd-based copy/paste in Neovide on macOS
  -- This uses the "logo" key (⌘) and maps it to system clipboard
  if is_macos then
    -- Allow ⌘ (logo) as a modifier in Neovide
    vim.g.neovide_input_use_logo = 1

    local map = vim.keymap.set
    local opts = { silent = true, noremap = true }

    -- Copy: Cmd+C in normal/visual modes → system clipboard
    map({ "n", "v" }, "<D-c>", '"+y', vim.tbl_extend("force", opts, { desc = "Copy to system clipboard" }))

    -- Paste: Cmd+V from system clipboard
    map("n", "<D-v>", '"+p', vim.tbl_extend("force", opts, { desc = "Paste from system clipboard" }))
    map("v", "<D-v>", '"+p', vim.tbl_extend("force", opts, { desc = "Paste from system clipboard" }))

    -- Insert/command/terminal mode paste: use <C-r>+
    map("i", "<D-v>", "<C-r>+", vim.tbl_extend("force", opts, { desc = "Paste clipboard (insert)" }))
    map("c", "<D-v>", "<C-r>+", vim.tbl_extend("force", opts, { desc = "Paste clipboard (cmdline)" }))
    map("t", "<D-v>", "<C-r>+", vim.tbl_extend("force", opts, { desc = "Paste clipboard (terminal)" }))
  end
end

return M
