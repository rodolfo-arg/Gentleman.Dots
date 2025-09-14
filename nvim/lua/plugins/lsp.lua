-- Guard LazyVim's Mason integration on first start.
-- If mason-lspconfig isn't installed yet, disable Mason integration to avoid
-- 'module mason-lspconfig.mappings.server not found' errors during bootstrap.
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      local has_mason_lsp = pcall(require, "mason-lspconfig")
      if not has_mason_lsp then
        opts.mason = false
      end
    end,
  },
}

