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
  local needle = (partial or ""):lower()

  local function find_in(configs)
    for _, cfg in ipairs(configs or {}) do
      if type(cfg.name) == "string" and cfg.name:lower():find(needle, 1, true) then
        return cfg
      end
    end
  end

  local ft = vim.bo.filetype
  local cfg = find_in(dap.configurations[ft])
  if not cfg then
    -- Fallback: search all filetypes' configs so we can run globally
    for _, list in pairs(dap.configurations) do
      cfg = find_in(list)
      if cfg then
        break
      end
    end
  end
  if cfg then
    return dap.run(cfg)
  end
  vim.notify("No DAP config matching '" .. partial .. "' (searched current ft '" .. ft .. "' and all)", vim.log.levels.WARN)
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
        "<leader>dX",
        function()
          run_config_by_name("macOS")
        end,
        desc = "macOS: Build + Debug (scheme)",
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

      -- macOS (Xcode) build + debug for Flutter macOS target via LLDB
      do
        local is_mac = vim.fn.has("mac") == 1
        local xcodebuild = vim.fn.exepath("xcodebuild")

        -- Try to locate an LLDB adapter binary (lldb-vscode preferred on macOS)
        local function find_lldb()
          -- Prefer lldb-dap (Xcode 15+)
          local exe = vim.fn.exepath("lldb-dap")
          if exe ~= nil and exe ~= "" then
            return exe
          end
          if vim.fn.executable("xcrun") == 1 then
            local okd, outd = pcall(vim.fn.systemlist, { "xcrun", "-f", "lldb-dap" })
            if okd and type(outd) == "table" and #outd > 0 and outd[1] ~= "" and vim.fn.filereadable(outd[1]) == 1 then
              return outd[1]
            end
          end
          -- Next try lldb-vscode (older Xcode)
          exe = vim.fn.exepath("lldb-vscode")
          if exe ~= nil and exe ~= "" then
            return exe
          end
          if vim.fn.executable("xcrun") == 1 then
            local okv, outv = pcall(vim.fn.systemlist, { "xcrun", "-f", "lldb-vscode" })
            if okv and type(outv) == "table" and #outv > 0 and outv[1] ~= "" and vim.fn.filereadable(outv[1]) == 1 then
              return outv[1]
            end
          end
          -- Fallback to codelldb (mason)
          local codelldb = vim.fn.exepath("codelldb")
          if codelldb ~= nil and codelldb ~= "" then
            return codelldb
          end
          return ""
        end

        if is_mac and xcodebuild ~= nil and xcodebuild ~= "" then
          local function ensure_lldb_adapter()
            local lldb_exe = find_lldb()
            if lldb_exe ~= nil and lldb_exe ~= "" then
              dap.adapters.lldb = {
                type = "executable",
                command = lldb_exe,
                name = "lldb",
              }
              return true
            end
            return false
          end

          local _have_lldb = ensure_lldb_adapter()
          if not _have_lldb then
            vim.schedule(function()
              vim.notify(
                "nvim-dap: LLDB DAP not found (lldb-dap/lldb-vscode/codelldb). Will attempt again at launch.",
                vim.log.levels.WARN
              )
            end)
          end

          -- Cache last chosen scheme for convenience
          local last_scheme = nil

            -- Resolve the macOS project root (dir that contains Runner.xcworkspace|Runner.xcodeproj)
            local function is_macos_root(dir)
              if dir == nil or dir == "" then
                return false
              end
              if vim.fn.isdirectory(dir .. "/Runner.xcworkspace") == 1 then
                return true
              end
              if vim.fn.isdirectory(dir .. "/Runner.xcodeproj") == 1 then
                return true
              end
              return false
            end

            local function dirname(path)
              return (path:gsub("[\\/]$", ""):match("^(.*)[\\/].-$") or path)
            end

            local function macos_root()
              local start = vim.fn.getcwd()
              -- Directly CWD is macos root
              if is_macos_root(start) then
                return start
              end
              -- CWD/macos is macos root
              if is_macos_root(start .. "/macos") then
                return start .. "/macos"
              end
              -- Walk up parents looking for a macos dir
              local dir = start
              while dir and dir ~= "" do
                if is_macos_root(dir .. "/macos") then
                  return dir .. "/macos"
                end
                local parent = dirname(dir)
                if not parent or parent == dir then
                  break
                end
                dir = parent
              end
              -- Last resort: return start
              return start
            end

            -- Helpers to append to a single REPL (via dap-ui's repl element) without opening a second window
            local function has_dap_repl()
              for _, win in ipairs(vim.api.nvim_list_wins()) do
                local buf = vim.api.nvim_win_get_buf(win)
                if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "dap-repl" then
                  return true
                end
              end
              return false
            end

            local function ensure_repl()
              if not has_dap_repl() then
                pcall(function()
                  require("dapui").open()
                end)
              end
            end

            local function append_repl(lines)
              ensure_repl()
              local repl = require("dap").repl
              if type(lines) == "string" then
                lines = { lines }
              end
              for _, l in ipairs(lines or {}) do
                pcall(repl.append, l .. "\n")
              end
            end

            -- Run a shell command in CWD and append output to REPL (non-streaming)
            local function run_and_capture(cmd)
              append_repl({
                "",
                "[macOS] Running: " .. table.concat(cmd, " "),
                "",
              })
              local out = vim.fn.systemlist(cmd)
              -- Prepend indent for readability
              for i, l in ipairs(out) do
                out[i] = (l == "" and "" or ("  " .. l))
              end
              append_repl(out)
              local rc = vim.v.shell_error
              return rc == 0, out
            end

            -- Parse xcodebuild -showBuildSettings output for keys
            local function parse_build_settings(lines)
              local data = {}
              for _, l in ipairs(lines or {}) do
                local k, v = l:match("^%s*([%u_]+)%s*=%s*(.-)%s*$")
                if k and v then
                  data[k] = v
                end
              end
              return data
            end

            -- Resolve built binary path for the chosen scheme (and optional config)
            local function resolve_binary_path(scheme, config, root)
              -- Build using absolute workspace/project paths under detected macOS root
              local build_dir_flags = {}
              if vim.fn.isdirectory(root .. "/Runner.xcworkspace") == 1 then
                build_dir_flags = { "-workspace", root .. "/Runner.xcworkspace" }
              elseif vim.fn.isdirectory(root .. "/Runner.xcodeproj") == 1 then
                build_dir_flags = { "-project", root .. "/Runner.xcodeproj" }
              else
                return nil, "Could not find Runner.xcworkspace or Runner.xcodeproj under " .. root
              end

              -- 1) Read build settings
              local show_cmd = { "xcodebuild", "-showBuildSettings" }
              for _, v in ipairs(build_dir_flags) do table.insert(show_cmd, v) end
              table.insert(show_cmd, "-scheme")
              table.insert(show_cmd, scheme)
              table.insert(show_cmd, "-sdk")
              table.insert(show_cmd, "macosx")
              if config and config ~= "" then
                table.insert(show_cmd, "-configuration")
                table.insert(show_cmd, config)
              end
              local ok_settings, settings_lines = run_and_capture(show_cmd)
              if not ok_settings then
                return nil, "xcodebuild -showBuildSettings failed"
              end
              local settings = parse_build_settings(settings_lines)
              local built_dir = settings["BUILT_PRODUCTS_DIR"] or settings["CONFIGURATION_BUILD_DIR"]
              local exec_path = settings["EXECUTABLE_PATH"]
              if not built_dir or not exec_path or built_dir == "" or exec_path == "" then
                return nil, "Missing BUILT_PRODUCTS_DIR/EXECUTABLE_PATH in build settings"
              end

              -- 2) Build
              local build_cmd = { "xcodebuild" }
              for _, v in ipairs(build_dir_flags) do table.insert(build_cmd, v) end
              table.insert(build_cmd, "-scheme")
              table.insert(build_cmd, scheme)
              table.insert(build_cmd, "-sdk")
              table.insert(build_cmd, "macosx")
              table.insert(build_cmd, "build")
              if config and config ~= "" then
                table.insert(build_cmd, "-configuration")
                table.insert(build_cmd, config)
              end
              local ok_build = run_and_capture(build_cmd)
              if not ok_build then
                return nil, "xcodebuild build failed"
              end

              -- 3) Compute binary path
              local bin_path = built_dir .. "/" .. exec_path
              if vim.fn.filereadable(bin_path) ~= 1 then
                -- Some builds produce an app bundle only; attempt to read FULL_PRODUCT_NAME
                local app_name = settings["FULL_PRODUCT_NAME"]
                if app_name and app_name ~= "" then
                  local maybe_bin = built_dir .. "/" .. app_name .. "/Contents/MacOS/" .. (exec_path:match("([^/]+)$") or exec_path)
                  if vim.fn.filereadable(maybe_bin) == 1 then
                    bin_path = maybe_bin
                  end
                end
              end
              if vim.fn.filereadable(bin_path) ~= 1 then
                return nil, "Built binary not found at: " .. bin_path
              end
              return bin_path
            end

          -- Shared config object so we can register for multiple filetypes
          local macos_build_debug = {
            type = "lldb",
            request = "launch",
            name = "macOS: Build + Debug (choose scheme)",
            stopOnEntry = false,
            program = function()
              -- Ensure adapter availability at launch time
              if not dap.adapters["lldb"] then
                ensure_lldb_adapter()
              end

              -- Detect project root regardless of current buffer
              local root = macos_root()
              append_repl({ "[macOS] Project root: " .. root })

              -- Ask for scheme; default to last used or env or develop
              local default = last_scheme or os.getenv("DAP_XCODE_SCHEME") or "develop"
              local scheme = vim.fn.input("Xcode scheme (develop/staging/production): ", default)
              scheme = vim.trim(scheme)
              if scheme == "" then
                vim.notify("Scheme is required", vim.log.levels.ERROR)
                error("scheme required")
              end
              last_scheme = scheme

              -- Optional: read config from env (e.g., Debug/Release)
              local cfg = os.getenv("DAP_XCODE_CONFIG")

              append_repl({ "[macOS] Preparing build for scheme '" .. scheme .. "'" .. (cfg and (" (" .. cfg .. ")") or "") })

              local bin_path, err = resolve_binary_path(scheme, cfg, root)
              if not bin_path then
                vim.notify("macOS build failed: " .. (err or "unknown error"), vim.log.levels.ERROR)
                error(err or "macOS build failed")
              end
              append_repl({ "[macOS] Built binary: " .. bin_path })
              return bin_path
            end,
            env = load_env_variables,
            cwd = function()
              return (vim.fn.getcwd() ~= macos_root()) and macos_root() or vim.fn.getcwd()
            end,
          }

          -- Register for Dart (Flutter projects) and Swift so it's runnable from anywhere
          dap.configurations.dart = dap.configurations.dart or {}
          table.insert(dap.configurations.dart, macos_build_debug)
          dap.configurations.swift = dap.configurations.swift or {}
          table.insert(dap.configurations.swift, macos_build_debug)
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
