return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = function(_, opts)
    opts.scroll = opts.scroll or {}
    opts.scroll.enabled = false

    opts.picker = opts.picker or {}
    opts.picker.matcher = vim.tbl_deep_extend("force", opts.picker.matcher or {}, {
      smartcase = false,
      ignorecase = true,
    })

    opts.picker.sources = opts.picker.sources or {}
    local files_source = opts.picker.sources.files or {}
    local args = files_source.args or {}

    local has_ignore_case = false
    for _, value in ipairs(args) do
      if value == "--ignore-case" or value == "-i" then
        has_ignore_case = true
        break
      end
    end

    if not has_ignore_case then
      table.insert(args, "--ignore-case")
    end

    files_source.args = args
    opts.picker.sources.files = files_source
  end,
}
