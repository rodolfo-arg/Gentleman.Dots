-- This file contains the configuration for the nvim-dap plugin in Neovim.

-- Prompt and cache program args for "Run with Args"
local last_args = nil
local function get_args()
  local input = vim.fn.input("Args (space-separated): ", last_args or "")
  if input == nil then
    return {}
  end
  input = vim.trim(input)
  if input == "" then
    return {}
  end
  last_args = input
  return vim.split(input, "%s+", { trimempty = true })
end

-- Run a DAP configuration by partial name match for the current filetype
local function run_config_by_name(partial)
  local dap = require("dap")
  local ft = vim.bo.filetype
  local configs = dap.configurations[ft] or {}
  for _, cfg in ipairs(configs) do
    if type(cfg.name) == "string" and cfg.name:lower():find(partial:lower(), 1, true) then
      return dap.run(cfg)
    end
  end
  vim.notify("No DAP config matching '" .. partial .. "' for filetype '" .. ft .. "'", vim.log.levels.WARN)
end

return {
  {
    -- Plugin: nvim-dap
    -- URL: https://github.com/mfussenegger/nvim-dap
    -- Description: Debug Adapter Protocol client implementation for Neovim.
    "mfussenegger/nvim-dap",
    recommended = true, -- Recommended plugin
    desc = "Debugging support. Requires language specific adapters to be configured. (see lang extras)",

    dependencies = {
      -- Minimal DAP UI
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",

      -- Plugin: nvim-dap-virtual-text
      -- URL: https://github.com/theHamsta/nvim-dap-virtual-text
      -- Description: Virtual text for the debugger.
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {
          commented = true,
          virt_text_pos = "eol",
          highlight_changed_variables = true,
          all_frames = true,
        },
      },
    },

    -- Keybindings for nvim-dap
    keys = {
      { "<leader>d", "", desc = "+debug", mode = { "n", "v" } }, -- Group for debug commands
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
        end,
        desc = "Breakpoint Condition",
      },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "Toggle Breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "Continue",
      },
      {
        "<leader>da",
        function()
          require("dap").continue({ before = get_args })
        end,
        desc = "Run with Args",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval(nil, { enter = true })
        end,
        mode = { "n" },
        desc = "Eval Expression",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval(nil, { enter = true })
        end,
        mode = { "v" },
        desc = "Eval Selection",
      },
      {
        "<leader>du",
        function()
          require("dapui").toggle({ reset = true })
        end,
        desc = "Toggle UI",
      },
      {
        "<leader>dL",
        function()
          require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
        end,
        desc = "Set Logpoint",
      },
      {
        "<leader>dS",
        function()
          local widgets = require("dap.ui.widgets")
          widgets.centered_float(widgets.scopes)
        end,
        desc = "Scopes (Float)",
      },
      {
        "<leader>dC",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "Run to Cursor",
      },
      {
        "<leader>dg",
        function()
          require("dap").goto_()
        end,
        desc = "Go to Line (No Execute)",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "Step Into",
      },
      {
        "<leader>dj",
        function()
          require("dap").down()
        end,
        desc = "Down",
      },
      {
        "<leader>dk",
        function()
          require("dap").up()
        end,
        desc = "Up",
      },
      {
        "<leader>dl",
        function()
          require("dap").run_last()
        end,
        desc = "Run Last",
      },
      {
        "<leader>do",
        function()
          require("dap").step_out()
        end,
        desc = "Step Out",
      },
      {
        "<leader>dO",
        function()
          require("dap").step_over()
        end,
        desc = "Step Over",
      },
      {
        "<leader>dp",
        function()
          require("dap").pause()
        end,
        desc = "Pause",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        desc = "Toggle REPL",
      },
      {
        "<leader>dA",
        function()
          run_config_by_name("attach")
        end,
        desc = "Attach (Dart/Flutter)",
      },
      {
        "<leader>dM",
        function()
          run_config_by_name("main.dart")
        end,
        desc = "Launch main.dart",
      },
      {
        "<leader>dE",
        function()
          run_config_by_name("example")
        end,
        desc = "Launch example app",
      },
      {
        "<leader>ds",
        function()
          require("dap").session()
        end,
        desc = "Session",
      },
      {
        "<leader>dt",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate",
      },
      {
        "<leader>dw",
        function()
          require("dap.ui.widgets").hover()
        end,
        desc = "Widgets",
      },
    },

    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      -- Load mason-nvim-dap if available
      if LazyVim.has("mason-nvim-dap.nvim") then
        require("mason-nvim-dap").setup(LazyVim.opts("mason-nvim-dap.nvim"))
      end

      -- Dart / Flutter adapter
      do
        local dart_exe = vim.fn.exepath("dart")
        if dart_exe and dart_exe ~= "" then
          dap.adapters.dart = {
            type = "executable",
            command = dart_exe,
            args = { "debug_adapter" },
          }

          dap.configurations.dart = dap.configurations.dart or {}
          table.insert(dap.configurations.dart, {
            type = "dart",
            request = "launch",
            name = "Launch main.dart",
            program = "${workspaceFolder}/lib/main.dart",
            cwd = "${workspaceFolder}",
          })
          table.insert(dap.configurations.dart, {
            type = "dart",
            request = "launch",
            name = "Launch example (plugin)",
            program = "${workspaceFolder}/example/lib/main.dart",
            cwd = "${workspaceFolder}/example",
          })
          table.insert(dap.configurations.dart, {
            type = "dart",
            request = "attach",
            name = "Attach to Dart/Flutter",
            cwd = "${workspaceFolder}",
          })
        end
      end

      -- Set highlight for DapStoppedLine
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

      -- Define signs for DAP
      for name, sign in pairs(LazyVim.config.icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define(
          "Dap" .. name,
          { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
        )
      end

      -- Setup DAP configuration using VsCode launch.json file
      local vscode = require("dap.ext.vscode")
      local json = require("plenary.json")
      vscode.json_decode = function(str)
        return vim.json.decode(json.json_strip_comments(str))
      end

      -- Load launch configurations from .vscode/launch.json if it exists
      if vim.fn.filereadable(".vscode/launch.json") then
        -- Map VSCode's "dart" type to Neovim's dart filetype
        vscode.load_launchjs(nil, { dart = { "dart" } })
      end

      -- Function to load environment variables (merge current env + optional .env)
      local function load_env_variables()
        local out = {}
        for k, v in pairs(vim.fn.environ()) do
          out[k] = v
        end
        local env_path = vim.fn.getcwd() .. "/.env"
        local f = io.open(env_path, "r")
        if f then
          for line in f:lines() do
            local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
            if key and value and key ~= "" then
              -- strip surrounding quotes if any
              value = value:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
              out[key] = value
            end
          end
          f:close()
        end
        return out
      end

      -- Add env provider to Dart configurations
      for _, config in ipairs(dap.configurations.dart or {}) do
        config.env = load_env_variables
      end

      -- Minimal dap-ui: side-by-side Variables (scopes) and Controls (in repl) using half screen width
      local half_cols = math.floor((vim.o.columns or 160) * 0.5)
      if half_cols < 60 then
        half_cols = 60
      end
      dapui.setup({
        layouts = {
          {
            elements = {
              { id = "scopes" },
            },
            size = 40,
            position = "left",
          },
          {
            elements = {
              { id = "repl" },
            },
            size = 12,
            position = "bottom",
          },
        },
        controls = {
          enabled = true,
          element = "repl",
        },
        expand_lines = true,
        floating = { border = "rounded" },
      })

      -- DAP UI theming: explicit colors for clarity across themes
      local function set_dapui_highlights()
        -- Choose a purple that matches the active theme where possible
        local scheme = (vim.g.colors_name or ""):lower()
        local purple
        if scheme:find("kanagawa") or scheme:find("gentleman%-kanagawa") then
          purple = "#A48CF2" -- Kanagawa Fuji Purple
        elseif scheme:find("catppuccin") or scheme:find("mocha") then
          purple = "#CBA6F7" -- Catppuccin Mauve
        else
          purple = "#CBA6F7" -- sensible default
        end
        local white = "#FFFFFF"
        local set = function(name, spec)
          pcall(vim.api.nvim_set_hl, 0, name, spec)
        end

        -- Make variable names pop
        set("DapUIVariable", { fg = purple, bold = true })

        -- Keep most other text clean/neutral
        set("DapUIValue", { fg = white })
        set("DapUIType", { fg = white })
        set("DapUISource", { fg = white })
        set("DapUIThread", { fg = white })
        set("DapUIStoppedThread", { fg = white })
        set("DapUILineNumber", { fg = white })
        set("DapUIDecoration", { fg = white })
        set("DapUIWatchesEmpty", { fg = white })
        set("DapUIWatchesValue", { fg = white })
        set("DapUIWatchesNone", { fg = white })
        set("DapUIBreakpointsPath", { fg = white })
        set("DapUIBreakpointsInfo", { fg = white })
        set("DapUIBreakpointsCurrentLine", { fg = white })
        set("DapUIBreakpointsLine", { fg = white })
        set("DapUIBreakpointsDisabledLine", { fg = white })
        set("DapUIReplPrompt", { fg = white, bold = true })

        -- Respect theme border for floats
        pcall(vim.api.nvim_set_hl, 0, "DapUIFloatBorder", { link = "FloatBorder" })

        -- Virtual text subtle
        pcall(vim.api.nvim_set_hl, 0, "NvimDapVirtualText", { link = "DiagnosticHint" })
      end

      set_dapui_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("GentlemanDapUIColors", { clear = true }),
        callback = set_dapui_highlights,
      })

      -- Open minimal UI on start, close on end.
      -- If neo-tree is open, also close its paired side-terminal so it doesn't take over the column.
      dap.listeners.after.event_initialized["dapui_minimal"] = function()
        local function any_win_with_ft(ft)
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == ft then
              return true
            end
          end
          return false
        end

        local had_neotree = any_win_with_ft("neo-tree")
        -- Always attempt to close neo-tree (noop if not open)
        pcall(vim.cmd, "Neotree close")

        -- If neo-tree was open, close only the terminal(s) paired under its column
        if had_neotree then
          local tab = vim.api.nvim_get_current_tabpage()
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "terminal" then
              local ok, flag = pcall(vim.api.nvim_buf_get_var, buf, "__neotree_side_terminal")
              if ok and flag then
                pcall(vim.api.nvim_win_close, win, true)
              end
            end
          end
        end

        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_minimal"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_minimal"] = function()
        dapui.close()
      end
    end,
  },
}
