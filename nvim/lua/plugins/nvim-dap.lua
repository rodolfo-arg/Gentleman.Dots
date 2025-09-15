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
    "mfussenegger/nvim-dap",
    recommended = true,
    desc = "Debugging support. Requires language specific adapters to be configured. (see lang extras)",

    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
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

    keys = {
      { "<leader>d", "", desc = "+debug", mode = { "n", "v" } },
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

      -- NEW: Native iOS/macOS commands
      {
        "<leader>dX",
        function()
          run_config_by_name("macOS")
        end,
        desc = "Build & Launch macOS App",
      },
      {
        "<leader>dP",
        function()
          run_config_by_name("iOS Device App")
        end,
        desc = "Build & Launch iOS Device App",
      },
      {
        "<leader>dD",
        function()
          run_config_by_name("Attach to iOS Device")
        end,
        desc = "Attach to iOS Device",
      },
    },

    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

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

      -- LLDB Adapter
      dap.adapters.lldb = {
        type = "executable",
        command = (function()
          local exe = vim.fn.exepath("lldb-dap")
          if exe ~= "" then
            return exe
          end
          -- fallback: use xcrun to locate it
          local handle = io.popen("xcrun --find lldb-dap 2>/dev/null")
          if handle then
            local result = handle:read("*l") or ""
            handle:close()
            return result
          end
          return "" -- will trigger error if still missing
        end)(),
        name = "lldb",
      }

      -- Auto-detect device UDID via xcdevice
      local function get_default_ios_device_udid()
        local handle = io.popen("xcrun xcdevice list --json")
        if not handle then
          return nil
        end
        local result = handle:read("*a")
        handle:close()
        local ok, devices = pcall(vim.json.decode, result)
        if not ok or not devices then
          return nil
        end
        for _, dev in ipairs(devices) do
          if dev.isConnected and dev.platform == "iOS" then
            return dev.udid
          end
        end
        return nil
      end
      local function project_dir(target)
        local cwd = vim.fn.getcwd()
        if target == "ios-device" then
          if vim.fn.isdirectory(cwd .. "/ios") == 1 then
            return cwd .. "/ios"
          end
        else
          if vim.fn.isdirectory(cwd .. "/macos") == 1 then
            return cwd .. "/macos"
          end
        end
        return cwd
      end
      -- Build helper
      -- Build helper using dynamic settings
      local function build_and_get_binary(target)
        local proj_dir = project_dir(target)

        local function get_build_settings(sdk, config, extra)
          local cmd = string.format(
            "cd %s && xcodebuild -showBuildSettings -sdk %s -configuration %s %s",
            proj_dir,
            sdk,
            config or "Debug",
            extra or ""
          )
          local handle = io.popen(cmd)
          if not handle then
            return {}
          end
          local result = handle:read("*a")
          handle:close()

          local settings = {}
          for k, v in result:gmatch("([%w_]+) = (.+)") do
            settings[k] = v
          end
          return settings
        end

        if target == "ios-device" then
          local udid = get_default_ios_device_udid()
          if not udid then
            vim.notify("No connected iOS device found", vim.log.levels.ERROR)
            return ""
          end

          local settings =
            get_build_settings("iphoneos", "Debug", string.format("-destination 'platform=iOS,id=%s'", udid))
          local exe = settings["EXECUTABLE_NAME"] or "Runner"
          local products = settings["BUILT_PRODUCTS_DIR"] or (proj_dir .. "/build/Debug")

          vim.fn.jobstart(
            string.format(
              "cd %s && xcodebuild -scheme Runner -destination 'platform=iOS,id=%s' -configuration %s build",
              proj_dir,
              udid,
              settings["CONFIGURATION"] or "Debug"
            ),
            { detach = true }
          )

          return string.format("%s/%s.app/%s", products, exe, exe)
        else
          -- macOS build
          local settings = get_build_settings("macosx", "Debug-develop")
          local exe = settings["EXECUTABLE_NAME"] or "Runner"
          local products = settings["BUILT_PRODUCTS_DIR"] or (proj_dir .. "/build/Debug-develop")

          vim.fn.jobstart(
            string.format(
              "cd %s && xcodebuild -scheme Runner -sdk macosx -configuration %s build",
              proj_dir,
              settings["CONFIGURATION"] or "Debug-develop"
            ),
            { detach = true }
          )

          return string.format("%s/%s.app/Contents/MacOS/%s", products, exe, exe)
        end
      end

      -- Native configs
      local native_configs = {
        {
          name = "Launch macOS App",
          type = "lldb",
          request = "launch",
          program = function()
            return build_and_get_binary("macos")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = get_args,
        },
        {
          name = "Launch iOS Device App",
          type = "lldb",
          request = "launch",
          program = function()
            return build_and_get_binary("ios-device")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = get_args,
        },
        {
          name = "Attach to iOS Device",
          type = "lldb",
          request = "attach",
          pid = require("dap.utils").pick_process,
          cwd = "${workspaceFolder}",
        },
      }

      dap.configurations.swift = native_configs
      dap.configurations.objc = native_configs
      dap.configurations.cpp = native_configs
      dap.configurations.c = native_configs

      -- UI & theming (unchanged from your base config)
      vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
      for name, sign in pairs(LazyVim.config.icons.dap) do
        sign = type(sign) == "table" and sign or { sign }
        vim.fn.sign_define(
          "Dap" .. name,
          { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
        )
      end

      local vscode = require("dap.ext.vscode")
      local json = require("plenary.json")
      vscode.json_decode = function(str)
        return vim.json.decode(json.json_strip_comments(str))
      end
      if vim.fn.filereadable(".vscode/launch.json") then
        vscode.load_launchjs(nil, { dart = { "dart" } })
      end

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
              value = value:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
              out[key] = value
            end
          end
          f:close()
        end
        return out
      end
      for _, config in ipairs(dap.configurations.dart or {}) do
        config.env = load_env_variables
      end

      dapui.setup({
        layouts = {
          { elements = { { id = "scopes" } }, size = 40, position = "left" },
          { elements = { { id = "repl" } }, size = 12, position = "bottom" },
        },
        controls = { enabled = true, element = "repl" },
        expand_lines = true,
        floating = { border = "rounded" },
      })

      local function set_dapui_highlights()
        local scheme = (vim.g.colors_name or ""):lower()
        local purple
        if scheme:find("kanagawa") then
          purple = "#A48CF2"
        elseif scheme:find("catppuccin") then
          purple = "#CBA6F7"
        else
          purple = "#CBA6F7"
        end
        local white = "#FFFFFF"
        local set = function(name, spec)
          pcall(vim.api.nvim_set_hl, 0, name, spec)
        end
        set("DapUIVariable", { fg = purple, bold = true })
        set("DapUIValue", { fg = white })
      end
      set_dapui_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("GentlemanDapUIColors", { clear = true }),
        callback = set_dapui_highlights,
      })

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
