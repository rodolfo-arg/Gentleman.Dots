return {
  -- Inline ghost text like VSCode; disable completion popup integration
  {
    "zbirenbaum/copilot.lua",
    optional = true,
    opts = {
      panel = { enabled = false },
      suggestion = {
        enabled = false,
        auto_trigger = false,
        debounce = 75,
        keymap = {
          accept = "<C-Right>",
          accept_word = "<M-Right>",
          accept_line = "<M-l>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "<C-]>",
        },
      },
      filetypes = {
        yaml = false,
        markdown = false,
        help = false,
        gitcommit = false,
        gitrebase = false,
        hgcommit = false,
        svn = false,
        cvs = false,
        ["."] = false,
      },
    },
  },
  {
    -- Ensure LazyVim’s copilot-cmp does not hook into completion menu
    "zbirenbaum/copilot-cmp",
    enabled = false,
  },
}
