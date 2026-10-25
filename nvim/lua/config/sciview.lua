-- sciview: look at arrays from the paused program in an imgui/implot window.
--   show(expr)     send the value of `expr` (in the paused frame) to the
--                  viewer, starting the viewer first if needed (,m);
--                  with no expr, just open the viewer
--   request(name)  the same, called by the viewer when a variable is clicked
--   children(expr) the attributes of an object opened in the viewer
--   select_frame(id) go to that frame of the call stack (clicked in the viewer)
-- While the viewer is open, every pause (and frame change) also sends it the
-- call stack and the frame's variables, so it works as a variable explorer
-- that follows ,k / ,j, and moves the debugger to a frame clicked there.
-- The viewer (python/nvim_sciview.py) is its own process, using the active
-- env's python; python/nvim_sciview_send.py runs inside the paused program.
local M = {}

local helpers = vim.fn.stdpath("config") .. "/python"
local socket_path = (vim.env.XDG_RUNTIME_DIR or "/tmp") .. "/nvim-sciview-" .. vim.uv.getuid() .. ".sock"
local job = nil

local function python()
  local venv = vim.env.VIRTUAL_ENV
  return venv and venv .. "/bin/python" or "python3"
end

-- is a viewer answering on the socket? (one started by another nvim counts)
local function reachable(cb)
  local pipe = vim.uv.new_pipe(false)
  pipe:connect(socket_path, function(err)
    pipe:close()
    vim.schedule(function()
      cb(err == nil)
    end)
  end)
end

-- the colorscheme, so the viewer looks like nvim: {role = "#rrggbb"}
local function theme()
  local function hl(name, attr)
    local value = vim.api.nvim_get_hl(0, { name = name, link = false })[attr]
    return value and string.format("#%06x", value)
  end
  local function darken(hex, f)
    local r, g, b = tonumber(hex:sub(2, 3), 16), tonumber(hex:sub(4, 5), 16), tonumber(hex:sub(6, 7), 16)
    return string.format("#%02x%02x%02x", r * f, g * f, b * f)
  end
  local raised = hl("CursorLine", "bg") or hl("Visual", "bg") or "#2a2e3f"
  return {
    -- a transparent Normal has no bg: a shade darker than the cursor line
    bg = hl("Normal", "bg") or hl("NormalFloat", "bg") or darken(raised, 0.62),
    raised = raised,
    selection = hl("Visual", "bg") or raised,
    fg = hl("Normal", "fg") or "#c0caf5",
    dim = hl("Comment", "fg") or "#565f89",
    accent = hl("Function", "fg") or "#7aa2f7",
    border = hl("FloatBorder", "fg") or hl("Comment", "fg") or "#565f89",
    number = hl("Number", "fg") or "#ff9e64",
    string = hl("String", "fg") or "#9ece6a",
    type = hl("Type", "fg") or "#2ac3de",
    constant = hl("Boolean", "fg") or hl("Constant", "fg") or "#ff9e64",
    error = hl("DiagnosticError", "fg") or "#db4b4b",
    ok = hl("DiagnosticOk", "fg") or hl("String", "fg") or "#9ece6a",
  }
end

local function ensure_viewer(cb)
  reachable(function(up)
    if up then
      return cb()
    end
    local stderr = {}
    -- vim.g.sciview_args: extra viewer arguments, e.g. { "--test-frames", "300" }
    -- --nvim: where the viewer asks for a variable when one is clicked
    -- --theme: its colors, from the colorscheme
    local cmd = vim.list_extend({ python(), helpers .. "/nvim_sciview.py", "--nvim", vim.v.servername,
      "--theme", vim.json.encode(theme()) }, vim.g.sciview_args or {})
    job = vim.fn.jobstart(cmd, {
      cwd = helpers,
      on_stderr = function(_, lines)
        vim.list_extend(stderr, lines)
      end,
      on_exit = function(_, code)
        job = nil
        -- 143/129: closed because nvim quit, not a failure
        if code ~= 0 and code ~= 143 and code ~= 129 then
          vim.notify("sciview exited (" .. code .. "):\n" .. table.concat(stderr, "\n"), vim.log.levels.ERROR)
        end
      end,
    })
    -- wait for the window and its socket (imgui start-up takes about a second)
    local tries = 0
    local function poll()
      tries = tries + 1
      reachable(function(ready)
        if ready then
          cb()
        elseif job and tries < 100 then
          vim.defer_fn(poll, 150)
        else
          vim.notify("sciview did not start", vim.log.levels.ERROR)
        end
      end)
    end
    vim.defer_fn(poll, 300)
  end)
end

-- words under the cursor that can't be the value meant: keywords and constants
local not_values = {}
for _, w in ipairs({ "None", "True", "False", "and", "or", "not", "in", "is", "if", "else", "elif", "for",
  "while", "return", "lambda", "def", "class", "import", "from", "as", "with", "yield", "pass", "del", "await" }) do
  not_values[w] = true
end

-- the expression to show for the cursor: the expression under it (`movie`,
-- `self.template`), or, when that's a keyword or constant like the `None` in
-- `movie = trace[:, None, None] ...`, the line's assignment target, else nil
function M.expr_at_cursor()
  local expr = vim.fn.expand("<cexpr>")
  if expr ~= "" and not not_values[expr] and expr:match("^[%a_]") then
    return expr
  end
  local target = vim.api.nvim_get_current_line():match("^%s*([%a_][%w_%.]*)%s*[%+%-%*/]?=[^=]")
  if target then
    return target
  end
  -- keywords, brackets, operators and blanks are not values (the `()` under
  -- a parenthesis is an empty tuple): nil, and ,m just opens the viewer
  return nil
end

-- one JSON line to the viewer, if it's up (no viewer: nothing happens)
local function message(msg)
  local pipe = vim.uv.new_pipe(false)
  pipe:connect(socket_path, function(err)
    if err then
      return pipe:close()
    end
    pipe:write(vim.json.encode(msg) .. "\n")
    pipe:read_start(function() -- its "ok", or the end: either way done
      pipe:read_stop()
      pipe:close()
    end)
  end)
end

-- which pause and frame values belong to: the viewer forgets opened objects
-- and loaded arrays from another one
local stop_id, pushed = 0, nil
local function stop_key(frame)
  return stop_id .. ":" .. frame.id
end

-- the paused frame's variables and the call stack, for the viewer's explorer
function M.push_variables()
  local session = require("dap").session()
  local frame = session and session.current_frame
  if not (session and session.stopped_thread_id and frame) then
    return
  end
  reachable(function(up)
    if not up then
      return
    end
    local layout = require("config.dap_layout")
    local stack = {}
    for _, f in ipairs(layout.frames(session)) do
      stack[#stack + 1] = {
        id = f.id,
        name = f.name,
        location = layout.frame_location(f),
        subtle = f.presentationHint == "subtle" or f.presentationHint == "label",
      }
    end
    require("config.dap_popups").frame_listing(session, frame, function(variables)
      local file = frame.source and (frame.source.path or frame.source.name) or ""
      message({
        kind = "variables",
        stop = stop_key(frame),
        frame = frame.name,
        frame_id = frame.id,
        location = vim.fn.fnamemodify(file, ":t") .. ":" .. tostring(frame.line),
        stack = stack,
        variables = variables,
      })
    end)
  end)
end

-- called by the viewer (`nvim --server ... --remote-expr`) when a variable
-- is clicked; returns at once, the value follows like ,m
function M.request(name)
  vim.schedule(function()
    M.show(name)
  end)
  return ""
end

-- called by the viewer when an object is opened in its explorer: sends the
-- attributes / items of `expr` (in the paused frame) as a "children" message
function M.children(expr)
  vim.schedule(function()
    local session = require("dap").session()
    local frame = session and session.current_frame
    if not (session and session.stopped_thread_id and frame) then
      return message({ kind = "children", parent = expr, children = {}, error = "not paused" })
    end
    require("config.dap_popups").children_listing(session, frame, expr, function(children, err)
      message({ kind = "children", stop = stop_key(frame), parent = expr, children = children, error = err })
    end)
  end)
  return ""
end

-- called by the viewer when a frame of its call stack is clicked: the same
-- as ,k / ,j to it (the code window follows, the variables are sent again)
function M.select_frame(id)
  vim.schedule(function()
    local session = require("dap").session()
    if not (session and session.stopped_thread_id) then
      return
    end
    for _, frame in ipairs(require("config.dap_layout").frames(session)) do
      if frame.id == tonumber(id) then
        return session:_frame_set(frame)
      end
    end
  end)
  return ""
end

local dap = require("dap")
dap.listeners.after.event_stopped["sciview"] = function()
  stop_id = stop_id + 1
end
-- a frame's scopes are fetched when it's shown (a pause, ,k/,j)
dap.listeners.after.scopes["sciview"] = function(session, _, _, request)
  local frame = session.current_frame
  local key = frame and stop_key(frame)
  if frame and request and request.frameId == frame.id and key ~= pushed then
    pushed = key
    vim.schedule(M.push_variables)
  end
end
for _, event in ipairs({ "event_continued", "event_terminated", "event_exited" }) do
  dap.listeners.after[event]["sciview"] = function()
    message({ kind = "running" })
  end
end

-- no `expr` (nothing under the cursor): just open the viewer, whose explorer
-- lists the paused frame's variables
function M.show(expr)
  if not expr or expr == "" then
    return ensure_viewer(M.push_variables)
  end
  local session = require("dap").session()
  local frame = session and session.current_frame
  if not (session and session.stopped_thread_id and frame) then
    vim.notify("sciview: `" .. expr .. "` can be sent while the debugger is paused", vim.log.levels.WARN)
    return ensure_viewer(function() end)
  end
  ensure_viewer(function()
    M.push_variables()
    local code = string.format("__import__('runpy').run_path(%q)['show'](%q, %s)", helpers .. "/nvim_sciview_send.py", expr, expr)
    session:request("evaluate", { expression = code, frameId = frame.id, context = "clipboard" }, function(err, resp)
      if err then
        return vim.notify("sciview: " .. (err.message or vim.inspect(err)), vim.log.levels.ERROR)
      end
      local text = resp.result:gsub("^['\"]", ""):gsub("['\"]$", "")
      -- an exception in the paused program comes back as its repr, e.g.
      -- TypeError('x: not a numeric array (NoneType)')
      local failed = text:match("^%w*Error%(") or text:match("^%w*Exception%(")
      vim.notify(failed and ("could not show `" .. expr .. "`: " .. text) or text,
        failed and vim.log.levels.ERROR or vim.log.levels.INFO, { title = "sciview" })
    end)
  end)
end

return M
