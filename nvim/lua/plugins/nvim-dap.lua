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

      -- Open minimal UI on start, close on end; also close Neo-tree to avoid layout clash
      dap.listeners.after.event_initialized["dapui_minimal"] = function()
        pcall(vim.cmd, "Neotree close")
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
