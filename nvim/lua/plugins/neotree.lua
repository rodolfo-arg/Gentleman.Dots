return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = function(_, opts)
      opts = opts or {}
      opts.filesystem = opts.filesystem or {}
      -- Avoid prompts about changing cwd on reveal; we reopen tree without reveal
      opts.filesystem.follow_current_file = opts.filesystem.follow_current_file or {}
      opts.filesystem.follow_current_file.enabled = false
      -- Keep neo-tree bound to the global cwd (restored from session)
      opts.filesystem.bind_to_cwd = true
      opts.filesystem.use_libuv_file_watcher = true
      opts.window = opts.window or {}
      opts.window.position = opts.window.position or "left"
      return opts
    end,
  },
}

