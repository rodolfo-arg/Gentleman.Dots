return {
  "sudo-tee/opencode.nvim",
  config = function()
    require("opencode").setup({
      keymap = {
        global = {
          toggle = "<leader>aa", -- open/close chat
        },
      },
    })

    vim.api.nvim_create_autocmd("BufWinEnter", {
      pattern = { "opencode_input", "opencode_output", "opencode_chat" },
      callback = function()
        local total = vim.o.columns
        local target = math.floor(total * 0.25)
        vim.api.nvim_win_set_width(0, target)
      end,
    })

    -- Always enter insert mode in chat input
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "opencode://chat/*",
      callback = function()
        vim.cmd("startinsert")
      end,
    })

    -- Window navigation inside chat buffers
    vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "opencode://chat/*",
      callback = function()
        -- Normal mode movement
        vim.keymap.set("n", "<C-h>", "<C-w>h", { buffer = true })
        vim.keymap.set("n", "<C-j>", "<C-w>j", { buffer = true })
        vim.keymap.set("n", "<C-k>", "<C-w>k", { buffer = true })
        vim.keymap.set("n", "<C-l>", "<C-w>l", { buffer = true })

        -- Insert mode (escape → move → back to insert)
        vim.keymap.set("i", "<C-h>", [[<Esc><C-w>h]], { buffer = true })
        vim.keymap.set("i", "<C-j>", [[<Esc><C-w>j]], { buffer = true })
        vim.keymap.set("i", "<C-k>", [[<Esc><C-w>k]], { buffer = true })
        vim.keymap.set("i", "<C-l>", [[<Esc><C-w>l]], { buffer = true })
      end,
    })

    -- Prevent focus stealing
    vim.g.opencode_focus_response = false
  end,
  dependencies = { "nvim-lua/plenary.nvim" },
}
