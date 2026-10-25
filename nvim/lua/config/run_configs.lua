-- ,dd: saved run commands per project, debugged with <CR>. Two boxes, each a
-- plain buffer saved when closed (<Tab> moves between them):
--   Variables    `NAME = value` lines, e.g. `SAMPLE = ~/data/demoMovie.tif`
--   Run configs  one command per line, as you'd type it in a shell; `dd`
--                deletes, `yyp` copies, edit args in place:
--     masknmf run --pipeline one-photon-culture $SAMPLE --fs 30   (an env command)
--     scripts/foo.py $SAMPLE --n 3                                (a file)
--     -m package.module --flag                                    (a module)
-- Commands use variables as $NAME or ${NAME} (else the environment's), and
-- ~ is your home; no shell runs them, so nothing else is expanded. Lines
-- starting with # are notes, and one right above a command is its name.
-- Stored per project root in stdpath("data")/run_configs.json, not in the
-- repo. The viewer's run configs page (,dv) edits the same store as a form.
-- run_to_here() (,s when not debugging) asks which command to run, the last
-- one used first, and stops only at the cursor line.
local M = {}

local STORE = vim.fn.stdpath("data") .. "/run_configs.json"
local HINT = "one command per line, e.g.  scripts/run.py $SAMPLE --n 3   or   -m pytest tests -k sample"
local VARIABLES_HINT = "NAME = value, e.g.  SAMPLE = ~/data/demoMovie.tif   (commands use it as $SAMPLE)"
local ns = vim.api.nvim_create_namespace("run_configs")

-- { [root] = commands, variables = { [root] = lines }, last = { [root] = command } }
local function read_store()
  local file = io.open(STORE)
  if not file then
    return {}
  end
  local ok, data = pcall(vim.json.decode, file:read("*a"))
  file:close()
  return ok and type(data) == "table" and data or {}
end

local function write_store(data)
  local file = io.open(STORE, "w")
  if file then
    file:write(vim.json.encode(data))
    file:close()
  end
end

local function project_root()
  return vim.fs.root(0, { ".git", "pyproject.toml" }) or vim.fn.getcwd()
end

local function is_command(line)
  return line:match("%S") ~= nil and not line:match("^%s*#")
end

-- shell-like split: spaces separate, quotes group
local function split(line)
  local args, current, quote = {}, nil, nil
  for char in line:gmatch(".") do
    if quote then
      if char == quote then
        quote = nil
      else
        current = (current or "") .. char
      end
    elseif char == '"' or char == "'" then
      quote, current = char, current or ""
    elseif char:match("%s") then
      if current then
        args[#args + 1], current = current, nil
      end
    else
      current = (current or "") .. char
    end
  end
  if current then
    args[#args + 1] = current
  end
  return args
end

local function home(text)
  return (text:gsub("^~/", vim.env.HOME .. "/"))
end

-- `NAME = value`, also written the shell ways: `$NAME = value`,
-- `export NAME=value`, a quoted value
local function parse_variables(lines)
  local variables = {}
  for _, line in ipairs(lines) do
    local name, value = line:gsub("^%s*export%s+", ""):match("^%s*%$?([%a_][%w_]*)%s*=%s*(.-)%s*$")
    if name then
      value = value:match('^"(.*)"$') or value:match("^'(.*)'$") or value
      variables[name] = home(value)
    end
  end
  return variables
end

-- one argument with $NAME / ${NAME} and a leading ~ filled in; the names
-- neither the variables nor the environment have go in `missing`
local function expand(arg, variables, missing)
  local function value(name)
    local found = variables[name] or vim.env[name]
    if not found then
      missing[#missing + 1] = "$" .. name
    end
    return found
  end
  arg = arg:gsub("%${([%a_][%w_]*)}", value):gsub("%$([%a_][%w_]*)", value)
  return home(arg)
end

local function pythonpath(root)
  local paths = { root }
  if vim.uv.fs_stat(root .. "/src") then
    table.insert(paths, 1, root .. "/src") -- src layout
  end
  if vim.env.PYTHONPATH and vim.env.PYTHONPATH ~= "" then
    table.insert(paths, vim.env.PYTHONPATH)
  end
  return table.concat(paths, ":")
end

-- this run stops only at `stop_at`: the other breakpoints are put aside until
-- it stops (or ends, or never starts), then come back
local function only_stop_at(stop_at)
  local dap, breakpoints = require("dap"), require("dap.breakpoints")
  local saved = breakpoints.get()
  saved[stop_at.buf] = saved[stop_at.buf] or {} -- so the one at the cursor is removed too
  breakpoints.clear()
  breakpoints.set({}, stop_at.buf, stop_at.line)
  local restored = false
  local function restore(session)
    if restored then
      return
    end
    restored = true
    for _, event in ipairs({ "event_stopped", "event_terminated" }) do
      dap.listeners.before[event]["run_configs"] = nil
    end
    breakpoints.clear()
    for buf, list in pairs(saved) do
      for _, bp in ipairs(list) do
        local opts = { condition = bp.condition, log_message = bp.logMessage, hit_condition = bp.hitCondition }
        breakpoints.set(opts, buf, bp.line)
      end
    end
    if session then
      session:set_breakpoints(saved)
    end
  end
  for _, event in ipairs({ "event_stopped", "event_terminated" }) do
    dap.listeners.before[event]["run_configs"] = restore
  end
  vim.defer_fn(function()
    if not dap.session() then
      restore()
    end
  end, 10000)
end

local function python()
  local venv = vim.env.VIRTUAL_ENV
  return venv and vim.uv.fs_stat(venv .. "/bin/python") and venv .. "/bin/python" or "python3"
end

-- the saved commands with their names: a # line right above a command names it
local function named(lines)
  local list = {}
  for i, line in ipairs(lines or {}) do
    if is_command(line) then
      local name = (lines[i - 1] or ""):match("^%s*#%s*(.-)%s*$")
      list[#list + 1] = { line = line, name = name ~= "" and name or nil }
    end
  end
  return list
end

-- quoted for a shell only where needed, so a copied command stays readable
local function shell_quote(arg)
  if arg ~= "" and not arg:find("[^%w@%%+=:,./_-]") then
    return arg
  end
  return "'" .. arg:gsub("'", "'\\''") .. "'"
end

local function remember(root, line)
  local store = read_store()
  store.last = store.last or {}
  store.last[root] = line
  write_store(store)
end

-- `line` as the debugger runs it: variables filled in, the program found.
-- Also what the viewer reads its --help with, runs, or copies (argv, shell);
-- nil and the reason when a variable isn't set
local function resolve(line, root)
  local store = read_store()
  local variables = parse_variables((store.variables or {})[root] or {})
  local args, missing = {}, {}
  for _, arg in ipairs(split(line)) do
    args[#args + 1] = expand(arg, variables, missing)
  end
  if #missing > 0 then
    return nil, table.concat(missing, ", ") .. " not set: add it under Variables in ,dd, or Data locations in ,dv"
  end
  if #args == 0 then
    return nil, "no command"
  end

  local config = {
    type = "python",
    request = "launch",
    name = line,
    cwd = root,
    justMyCode = true,
    pythonArgs = { "-X", "frozen_modules=off" },
    console = "internalConsole",
    -- don't follow child processes: masknmf starts one while importing,
    -- and the debugger following it ends the run
    subProcess = false,
    -- the project's own code comes first, like PyCharm's "add content roots
    -- to PYTHONPATH": breakpoints in it stop even when the env has a
    -- non-editable copy of the package installed
    env = { PYTHONPATH = pythonpath(root) },
  }
  local first = table.remove(args, 1)
  local shell
  if first == "-m" then
    config.module = table.remove(args, 1)
    shell = { "python", "-m", config.module }
  else
    -- a command installed in the env (masknmf, pytest, ...) is a python script
    local venv = vim.env.VIRTUAL_ENV
    local command = venv and venv .. "/bin/" .. first
    local installed = not first:find("/") and command and vim.uv.fs_stat(command) ~= nil
    config.program = installed and command or first
    shell = installed and { first } or { "python", first }
  end
  config.args = args
  local argv = { python() }
  vim.list_extend(argv, config.module and { "-m", config.module } or { config.program })
  for _, arg in ipairs(args) do
    shell[#shell + 1] = arg
  end
  local how = {
    argv = vim.list_extend(argv, args),
    installed = config.module == nil and config.program ~= first,
    shell = table.concat(vim.tbl_map(shell_quote, shell), " "),
  }
  return config, how
end

-- debug `line` from the project's run configs; stop_at = { buf, line } stops
-- there and nowhere else
local function start(line, root, stop_at, name)
  local config, err = resolve(line, root)
  if not config then
    return vim.notify(err, vim.log.levels.ERROR, { title = "Run configs" })
  end
  config.name = name or line
  remember(root, line)
  if stop_at then
    only_stop_at(stop_at)
  end
  require("dap").run(config)
end

-- ,s with nothing being debugged: pick a command (the last one run first),
-- run it, and stop at the cursor line
function M.run_to_here()
  local stop_at = { buf = vim.api.nvim_get_current_buf(), line = vim.api.nvim_win_get_cursor(0)[1] }
  local root = project_root()
  local store = read_store()
  local commands = named(store[root])
  if #commands == 0 then
    vim.notify("no saved commands for " .. vim.fn.fnamemodify(root, ":t") .. ": add one in ,dd", vim.log.levels.WARN)
    return M.open()
  end
  local last = (store.last or {})[root]
  for i, command in ipairs(commands) do
    if command.line == last then
      table.insert(commands, 1, table.remove(commands, i))
      break
    end
  end
  local where = vim.fn.expand("%:t") .. ":" .. stop_at.line
  vim.ui.select(commands, {
    prompt = "Run until " .. where,
    format_item = function(command)
      return command.name and command.name .. "   " .. command.line or command.line
    end,
  }, function(command)
    if command then
      start(command.line, root, stop_at, command.name)
    end
  end)
end

-- Run (no debugger): in a terminal split at the bottom. A finished run's
-- window is reused; one still going is left alone, the new one beside it
local function run_in_terminal(config, how, name)
  local reuse, beside
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.b[buf].run_configs_job then
      if vim.fn.jobwait({ vim.b[buf].run_configs_job }, 0)[1] == -1 then
        beside = win
      else
        reuse = win
      end
    end
  end
  local buf = vim.api.nvim_create_buf(false, true)
  local win
  if reuse then
    local old = vim.api.nvim_win_get_buf(reuse)
    vim.api.nvim_win_set_buf(reuse, buf)
    vim.api.nvim_buf_delete(old, { force = true })
    win = reuse
  elseif beside then
    win = vim.api.nvim_open_win(buf, false, { split = "right", win = beside })
  else
    win = vim.api.nvim_open_win(buf, false, { split = "below", win = -1, height = 14 })
  end
  vim.wo[win].winfixheight = true
  vim.api.nvim_win_call(win, function()
    vim.b[buf].run_configs_job = vim.fn.jobstart(how.argv, { term = true, cwd = config.cwd, env = config.env })
  end)
  vim.wo[win].winbar = "%#DapPanelTitle# Run %#DapPanelBar# " .. name:gsub("%%", "%%%%")
end

-- for the viewer's run configs page (python/nvim_sciview.py), over
-- `nvim --remote-expr`: which project and store to show
function M.viewer_state()
  return vim.json.encode({ root = project_root(), store = STORE })
end

-- the viewer's buttons: { action, root, line, name } as JSON, the answer as
-- JSON too: { error } or { ok } (a status line), and for "resolve" how the
-- command runs ({ argv, cwd, env, shell, installed, program, module })
function M.from_viewer(request)
  local ok, args = pcall(vim.json.decode, request)
  if not ok or type(args) ~= "table" or not args.line then
    return vim.json.encode({ error = "bad request" })
  end
  local config, how = resolve(args.line, args.root)
  if not config then
    return vim.json.encode({ error = how })
  end
  local name = args.name or args.line
  if args.action == "resolve" then
    return vim.json.encode(vim.tbl_extend("force", how, {
      cwd = config.cwd,
      env = config.env,
      program = config.program,
      module = config.module,
    }))
  elseif args.action == "run" then
    remember(args.root, args.line)
    vim.schedule(function()
      run_in_terminal(config, how, name)
    end)
    return vim.json.encode({ ok = "running in nvim: " .. name })
  end
  if require("dap").session() then
    return vim.json.encode({ error = "already debugging: stop that run first" })
  end
  if args.action == "debug" then
    vim.schedule(function()
      start(args.line, args.root, nil, name)
    end)
    return vim.json.encode({ ok = "debugging: " .. name })
  elseif args.action == "run_to_cursor" then
    -- nvim's cursor, in the code window you were last in
    local win = require("config.dap_layout").code_win()
    if not win then
      return vim.json.encode({ error = "no file open in nvim to stop in" })
    end
    local buf = vim.api.nvim_win_get_buf(win)
    local stop_at = { buf = buf, line = vim.api.nvim_win_get_cursor(win)[1] }
    vim.schedule(function()
      start(args.line, args.root, stop_at, name)
    end)
    return vim.json.encode({
      ok = "debugging, stops at " .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":t") .. ":" .. stop_at.line,
    })
  end
  return vim.json.encode({ error = "unknown action " .. tostring(args.action) })
end

function M.open()
  local root = project_root()
  local store = read_store()
  local commands = store[root] or { "" }
  local variables = (store.variables or {})[root] or { "" }

  local width = math.floor(vim.o.columns * 0.7)
  local variables_height = math.min(math.max(#variables, 1), 6)
  local commands_height = math.max(math.min(#commands + 2, math.floor(vim.o.lines * 0.5)), 5)
  local top = math.floor((vim.o.lines - variables_height - commands_height - 4) / 2) - 1
  local col = math.floor((vim.o.columns - width) / 2)

  -- an editable box: a scratch buffer in a bordered float, with a faint
  -- example while it's empty
  local function box(lines, hint, opts)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].bufhidden = "wipe"
    vim.bo[buf].syntax = "sh" -- highlights flags, $NAMEs and quoted paths (no filetype: no LSP)
    vim.bo[buf].formatoptions = "" -- `o` on a # note doesn't start another
    local function show_hint()
      vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
      local current = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      if #current == 1 and current[1] == "" then
        vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, { virt_text = { { hint, "Comment" } }, virt_text_pos = "overlay" })
      end
    end
    show_hint()
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, { buffer = buf, callback = show_hint })
    local win = vim.api.nvim_open_win(buf, opts.enter, {
      relative = "editor",
      width = width,
      height = opts.height,
      row = opts.row,
      col = col,
      border = "rounded",
      title = opts.title,
      title_pos = "center",
      footer = opts.footer,
      footer_pos = "right",
    })
    vim.wo[win].cursorline = opts.enter
    return buf, win
  end
  local variables_buf, variables_win = box(variables, VARIABLES_HINT, {
    row = top,
    height = variables_height,
    title = " Variables ",
    footer = " use as $NAME  <Tab> commands ",
    enter = false,
  })
  local commands_buf, commands_win = box(commands, HINT, {
    row = top + variables_height + 2,
    height = commands_height,
    title = " Run configs: " .. vim.fn.fnamemodify(root, ":t") .. " ",
    footer = " <CR> debug  <Tab> variables  dd delete  yyp copy  q close ",
    enter = true,
  })
  -- start on the first command, not a note
  for i, line in ipairs(commands) do
    if is_command(line) then
      vim.api.nvim_win_set_cursor(commands_win, { i, 0 })
      break
    end
  end

  local function kept(buf)
    local lines = vim.tbl_filter(function(l)
      return l:match("%S") ~= nil
    end, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    return #lines > 0 and lines or nil
  end
  local closed = false
  local function close()
    if closed then
      return
    end
    closed = true
    local data = read_store()
    data[root] = kept(commands_buf)
    data.variables = data.variables or {}
    data.variables[root] = kept(variables_buf)
    write_store(data)
    for _, win in ipairs({ variables_win, commands_win }) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
  end

  for _, pair in ipairs({ { variables_buf, commands_win }, { commands_buf, variables_win } }) do
    local buf, other = pair[1], pair[2]
    local map = function(lhs, fn)
      vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true })
    end
    map("q", close)
    map("<Esc>", close)
    map("<Tab>", function()
      vim.wo[vim.api.nvim_get_current_win()].cursorline = false
      vim.api.nvim_set_current_win(other)
      vim.wo[other].cursorline = true
    end)
    -- leaving both boxes (for another window, a picker) closes them, saved
    vim.api.nvim_create_autocmd("WinLeave", {
      buffer = buf,
      callback = function()
        vim.schedule(function()
          local current = vim.api.nvim_get_current_win()
          if current ~= variables_win and current ~= commands_win then
            close()
          end
        end)
      end,
    })
  end
  vim.keymap.set("n", "<CR>", function()
    local line = vim.api.nvim_get_current_line()
    if not is_command(line) then
      return
    end
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local name = row > 1
      and vim.api.nvim_buf_get_lines(commands_buf, row - 2, row - 1, false)[1]:match("^%s*#%s*(.-)%s*$")
    close()
    start(line, root, nil, name ~= "" and name or nil)
  end, { buffer = commands_buf, nowait = true })
end

return M
