-- Flutter launch.json runner
-- Reads .vscode/launch.json (JSON with comments) and lets you pick a
-- configuration to run via :FlutterRun using flutter-tools.nvim.

local M = {}

local function is_root(dir)
  if dir == nil or dir == '' then
    return true
  end
  local parent = dir:match("^(.*)/[^/]+/?$")
  return parent == nil or parent == dir
end

local function join_path(a, b)
  if a:sub(-1) == '/' then
    return a .. b
  end
  return a .. '/' .. b
end

local function dirname(path)
  return path:match("^(.*)/[^/]+/?$") or path
end

local function file_readable(path)
  return vim.fn.filereadable(path) == 1
end

-- Basic JSONC -> JSON converter: strips // and /* */ comments and trailing commas
local function jsonc_to_json(text)
  -- Strip comments while respecting strings
  local out = {}
  local in_str = false
  local escape = false
  local in_line = false
  local in_block = false
  local i = 1
  while i <= #text do
    local c = text:sub(i, i)
    local n = text:sub(i + 1, i + 1)
    if in_line then
      if c == "\n" then
        in_line = false
        table.insert(out, c)
      end
      i = i + 1
    elseif in_block then
      if c == "*" and n == "/" then
        in_block = false
        i = i + 2
      else
        i = i + 1
      end
    elseif in_str then
      table.insert(out, c)
      if not escape and c == '"' then
        in_str = false
      end
      escape = (c == "\\") and not escape
      if c ~= "\\" then
        escape = false
      end
      i = i + 1
    else
      if c == '"' then
        in_str = true
        table.insert(out, c)
        i = i + 1
      elseif c == "/" and n == "/" then
        in_line = true
        i = i + 2
      elseif c == "/" and n == "*" then
        in_block = true
        i = i + 2
      else
        table.insert(out, c)
        i = i + 1
      end
    end
  end
  local no_comments = table.concat(out)

  -- Remove trailing commas before } or ] (outside strings)
  out = {}
  in_str = false
  escape = false
  i = 1
  while i <= #no_comments do
    local c = no_comments:sub(i, i)
    if in_str then
      table.insert(out, c)
      if not escape and c == '"' then
        in_str = false
      end
      escape = (c == "\\") and not escape
      if c ~= "\\" then
        escape = false
      end
      i = i + 1
    else
      if c == '"' then
        in_str = true
        table.insert(out, c)
        i = i + 1
      elseif c == "," then
        -- look ahead past whitespace
        local j = i + 1
        while j <= #no_comments do
          local d = no_comments:sub(j, j)
          if d:match("%s") then
            j = j + 1
          else
            break
          end
        end
        local d = no_comments:sub(j, j)
        if d == "}" or d == "]" then
          -- skip comma
          i = i + 1
        else
          table.insert(out, c)
          i = i + 1
        end
      else
        table.insert(out, c)
        i = i + 1
      end
    end
  end
  return table.concat(out)
end

local function read_file(path)
  local ok, data = pcall(vim.fn.readfile, path)
  if not ok then
    return nil, "Failed to read " .. path
  end
  return table.concat(data, "\n"), nil
end

local function find_launch_json(start_dir)
  local dir = start_dir or vim.loop.cwd()
  while dir and not is_root(dir) do
    local candidate = join_path(dir, ".vscode/launch.json")
    if file_readable(candidate) then
      return candidate, dir
    end
    dir = dirname(dir)
  end
  -- final check at root
  local candidate = join_path(dir or vim.loop.cwd(), ".vscode/launch.json")
  if file_readable(candidate) then
    return candidate, dir or vim.loop.cwd()
  end
  return nil, nil
end

local function replace_workspace_folder(s, root)
  if type(s) ~= 'string' then
    return s
  end
  local out = s
  out = out:gsub("%${workspaceFolder}", root)
  out = out:gsub("%${workspaceRoot}", root)
  out = out:gsub("%${workspaceDirectory}", root)
  return out
end

local function build_flutter_args(entry)
  local args = { "-t", entry.target }
  if entry.args then
    for _, a in ipairs(entry.args) do
      table.insert(args, a)
    end
  end
  return args
end

local function parse_configs(launch_path, root_dir)
  local text, err = read_file(launch_path)
  if not text then
    return nil, err
  end
  local cleaned = jsonc_to_json(text)
  local decoder = (vim.json and vim.json.decode) or vim.fn.json_decode
  local ok, json = pcall(decoder, cleaned)
  if not ok or type(json) ~= 'table' then
    return nil, "Invalid launch.json format"
  end
  local out = {}
  local configs = json.configurations or {}
  for _, cfg in ipairs(configs) do
    -- Only handle flutter app launches for now
    if cfg and cfg.type == "dart" and cfg.request == "launch" then
      local program = cfg.program
      if program == nil or program == '' then
        -- Default to workspace/lib/main.dart when not provided
        program = join_path(root_dir, "lib/main.dart")
      else
        program = replace_workspace_folder(program, root_dir)
        -- skip test runner style configs for now (program == "test")
        if program == "test" then
          goto continue
        end
        if not program:match("^/") then
          program = join_path(root_dir, program)
        end
      end
      -- Ensure we have an absolute target path for -t
      local target = program
        local args = {}
        if type(cfg.args) == 'table' then
          for _, a in ipairs(cfg.args) do
            table.insert(args, tostring(a))
          end
        end
        local cwd = nil
        if type(cfg.cwd) == 'string' and #cfg.cwd > 0 then
          cwd = replace_workspace_folder(cfg.cwd, root_dir)
          if not cwd:match("^/") then
            cwd = join_path(root_dir, cwd)
          end
        end
        table.insert(out, {
          name = cfg.name or target,
          target = target,
          args = args,
          cwd = cwd,
        })
      ::continue::
    end
  end
  return out, nil
end

function M.run_from_launch()
  local launch_path, root = find_launch_json(vim.loop.cwd())
  if not launch_path then
    vim.notify(".vscode/launch.json not found in project", vim.log.levels.WARN)
    return
  end
  local entries, err = parse_configs(launch_path, root or vim.loop.cwd())
  if not entries or #entries == 0 then
    vim.notify(err or "No Dart launch configurations found", vim.log.levels.WARN)
    return
  end
  local items = {}
  for _, e in ipairs(entries) do
    table.insert(items, e.name)
  end
  vim.ui.select(items, { prompt = "Flutter launch configuration" }, function(choice, idx)
    if not choice then
      return
    end
    local entry = entries[idx]
    if vim.fn.exists(":FlutterRun") ~= 2 then
      vim.notify("FlutterRun command not found. Is flutter-tools loaded?", vim.log.levels.ERROR)
      return
    end
    local prev_cwd
    if entry.cwd and vim.fn.isdirectory(entry.cwd) == 1 then
      prev_cwd = vim.loop.cwd()
      pcall(vim.cmd, "lcd " .. vim.fn.fnameescape(entry.cwd))
    end
    -- Execute :FlutterRun with args using nvim_cmd to avoid quoting issues
    local ok, err2 = pcall(vim.api.nvim_cmd, { cmd = "FlutterRun", args = build_flutter_args(entry) }, {})
    if not ok then
      vim.notify("FlutterRun failed: " .. tostring(err2), vim.log.levels.ERROR)
    end
    if prev_cwd then
      pcall(vim.cmd, "lcd " .. vim.fn.fnameescape(prev_cwd))
    end
  end)
end

function M.setup()
  pcall(vim.api.nvim_create_user_command, "FlutterRunFromLaunch", function()
    M.run_from_launch()
  end, { desc = "Flutter Run from .vscode/launch.json" })
end

return M
