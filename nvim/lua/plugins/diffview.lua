-- This file configures Diffview for Git diff workflows in Neovim.

return {
  {
    -- Plugin: diffview.nvim
    -- URL: https://github.com/sindrets/diffview.nvim
    -- Description: Git diff UI with history and merge tools.
    "sindrets/diffview.nvim",
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>gd", "<cmd>DiffviewOpen<CR>", desc = "Diffview (Working Tree)" },
      { "<leader>gD", "<cmd>DiffviewClose<CR>", desc = "Diffview Close" },
      { "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", desc = "Diffview File History (File)" },
      { "<leader>gH", "<cmd>DiffviewFileHistory<CR>", desc = "Diffview File History (Repo)" },
    },
    opts = {
      enhanced_diff_hl = true,
      view = {
        default = {
          layout = "diff2_horizontal",
        },
      },
      hooks = {
        diff_buf_read = function()
          vim.opt_local.signcolumn = "yes:2"
        end,
      },
    },
  },
}
