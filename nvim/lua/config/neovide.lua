-- Neovide-specific configuration (GUI + keymaps)
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

  -- Scrolling animations (previous values)
  vim.g.neovide_scroll_animation_length = 0.05
  vim.g.neovide_scroll_animation_far_lines = 10

  -- Optional: keep GUI font consistent if already set elsewhere.
  -- You can customize the font via `:set guifont` or here if needed.
  -- Example (commented):
  vim.opt.guifont = { "Lilex", ":h15" }
  vim.g.neovide_opacity = 0.8
  vim.g.neovide_window_blurred = true

  -- Clipboard: enable Cmd-based copy/paste in Neovide on macOS
  -- - Use the "logo" key (⌘) as a modifier
  -- - Prefer unnamedplus so regular y/p use the system clipboard
  if is_macos then
    -- Allow ⌘ (logo) as a modifier in Neovide
    vim.g.neovide_input_use_logo = 1

    -- Route unnamed register to system clipboard for a mac-like experience
    vim.opt.clipboard = "unnamedplus"

    local map = vim.keymap.set
    local opts = { silent = true, noremap = true }

    -- Copy: Cmd+C
    -- - normal: copy current line (no operator-pending)
    -- - visual: copy selection
    map("n", "<D-c>", '"+yy', vim.tbl_extend("force", opts, { desc = "Copy line to clipboard" }))
    map("v", "<D-c>", '"+y', vim.tbl_extend("force", opts, { desc = "Copy to clipboard" }))

    -- Paste: Cmd+V
    -- - normal: paste after cursor from clipboard
    -- - visual: paste without clobbering clipboard (use black-hole register)
    map("n", "<D-v>", '"+p', vim.tbl_extend("force", opts, { desc = "Paste from clipboard" }))
    map("v", "<D-v>", '"_dP', vim.tbl_extend("force", opts, { desc = "Paste over selection (preserve clipboard)" }))

    -- Insert/command/terminal mode paste: use <C-r>+
    map("i", "<D-v>", "<C-r>+", vim.tbl_extend("force", opts, { desc = "Paste clipboard (insert)" }))
    map("c", "<D-v>", "<C-r>+", vim.tbl_extend("force", opts, { desc = "Paste clipboard (cmdline)" }))

    -- Terminal-mode paste: send clipboard contents to the terminal job
    map("t", "<D-v>", function()
      local text = vim.fn.getreg("+")
      -- Fallback to unnamed if + is empty (shouldn't happen with unnamedplus)
      if text == nil or text == "" then
        text = vim.fn.getreg('"')
      end
      if text and text ~= "" then
        -- Send to current terminal job (handles multiline)
        pcall(vim.fn.chansend, vim.b.terminal_job_id, text)
      end
    end, vim.tbl_extend("force", opts, { desc = "Paste clipboard (terminal)" }))
  end
end

return M
