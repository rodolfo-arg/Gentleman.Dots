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
  vim.g.neovide_cursor_animation_length = 0.08
  vim.g.neovide_cursor_trail_size = 0.6
  vim.g.neovide_cursor_animate_in_insert_mode = false
  vim.g.neovide_cursor_animate_command_line = false
  vim.g.neovide_curser_antialiasing = true
  vim.g.neovide_remember_window_size = true
  vim.g.neovide_scroll_animation_length = 0.080
  vim.g.neovide_scroll_animation_far_lines = 10

  do
    local group = vim.api.nvim_create_augroup("neovide_no_anim_in_term_cmd", { clear = true })
    local defaults = {
      cursor_anim = vim.g.neovide_cursor_animation_length or 0,
      scroll_anim = vim.g.neovide_scroll_animation_length or 0,
    }
    local function stop_anim()
      vim.g.neovide_cursor_animation_length = 0
      vim.g.neovide_scroll_animation_length = 0
    end
    local function restore_anim()
      vim.g.neovide_cursor_animation_length = defaults.cursor_anim
      vim.g.neovide_scroll_animation_length = defaults.scroll_anim
    end
    -- Terminal buffers
    vim.api.nvim_create_autocmd({ "TermEnter" }, {
      group = group,
      callback = stop_anim,
      desc = "Disable Neovide animations in terminal",
    })
    vim.api.nvim_create_autocmd({ "TermLeave" }, {
      group = group,
      callback = restore_anim,
      desc = "Restore Neovide animations after terminal",
    })
    vim.api.nvim_create_autocmd({ "CmdlineEnter", "CmdwinEnter" }, {
      group = group,
      callback = stop_anim,
      desc = "Disable Neovide animations in cmdline",
    })
    vim.api.nvim_create_autocmd({ "CmdlineLeave", "CmdwinLeave" }, {
      group = group,
      callback = restore_anim,
      desc = "Restore Neovide animations after cmdline",
    })
  end
  -- Scrolling animations (previous values)
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

  -- Open a Ghostty window when quitting Neovide
  -- Trigger on VimLeavePre so the job starts before Neovim fully exits
  do
    local group = vim.api.nvim_create_augroup("neovide_exit_spawn_ghostty", { clear = true })
    vim.api.nvim_create_autocmd("VimLeavePre", {
      group = group,
      callback = function()
        -- Be gentle if tools are missing and keep it non-blocking
        local sysname = vim.loop.os_uname().sysname
        if sysname == "Darwin" then
          if vim.fn.executable("open") == 1 then
            -- Open Ghostty app (creates a window if running, otherwise launches)
            pcall(vim.fn.jobstart, { "open", "-a", "Ghostty" }, { detach = true })
          end
        else
          -- Linux/other: prefer the ghostty CLI if available
          if vim.fn.executable("ghostty") == 1 then
            pcall(vim.fn.jobstart, { "ghostty" }, { detach = true })
          end
        end
      end,
      desc = "Spawn Ghostty on Neovide quit",
    })
  end
end

return M
