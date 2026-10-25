-- The debugging layout, PyCharm-style: the code on top, with the arrow on the
-- current frame's line, and along the bottom the debug console (type code to
-- evaluate it in that frame; program output) beside the call stack. ,k / ,j
-- move through the stack: the stack pane marks where you are, and the code
-- window follows.
--   open() / close() / toggle()   the bottom row (,D; opens when debugging starts)
--   switchbuf(buf, line, col)     where nvim-dap shows a frame: always a code
--                                 window, never the console or a panel
--   pause()                       pause the main thread (,p)
--   goto_current()                back to the arrow, from anywhere (,g)
-- The console is nvim-dap's REPL: one buffer, only ever hidden and shown again,
-- so its history stays and there is never a second one.
local M = {}

local api = vim.api
local HEIGHT = 12
local STACK_WIDTH = 0.35 -- of the editor

local stack_buf, stack_win = nil, nil
local line_frames = {} -- stack pane line -> frame
local code_win = nil -- the last window you were in that shows a file

local function is_panel(buf)
  local ft = vim.bo[buf].filetype
  return ft == "dap-repl" or ft == "dap_callstack" or ft:match("^dapui_") ~= nil
end

-- a split showing a file (or a source the adapter sent): where code goes
local function is_code_win(win)
  if not api.nvim_win_is_valid(win) or api.nvim_win_get_config(win).relative ~= "" or vim.wo[win].winfixbuf then
    return false
  end
  local buf = api.nvim_win_get_buf(win)
  return not is_panel(buf) and (vim.bo[buf].buftype == "" or vim.b[buf].dap_source_buf == true)
end

local function find_win(filetype)
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if vim.bo[api.nvim_win_get_buf(win)].filetype == filetype then
      return win
    end
  end
end

-- `masknmf/compression.py:120` for a file in an env, else the path from the cwd
function M.frame_location(frame)
  local source = frame.source or {}
  local path = source.path or source.name or "?"
  local short = path:match("site%-packages/(.+)$")
    or path:match("/lib/python[%d.]+/(.+)$")
    or vim.fn.fnamemodify(path, ":~:.")
  return short .. ":" .. tostring(frame.line)
end

-- the stopped thread's frames, outermost first like a Python traceback, so
-- ,k (up, toward the caller) moves up the list and ,j down toward the stop
function M.frames(session)
  local thread = session and session.stopped_thread_id and session.threads[session.stopped_thread_id]
  return vim.iter(thread and thread.frames or {}):rev():totable()
end

-- pause the main thread (,p and the viewer's button); dap.pause() asks
-- which one first, as torch and friends run several
function M.pause()
  local dap = require("dap")
  local session = dap.session()
  if not session then
    return
  end
  session:request("threads", nil, function(err, resp)
    local id
    for _, thread in ipairs(not err and resp and resp.threads or {}) do
      if thread.name == "MainThread" or not id then
        id = thread.id
      end
    end
    if id then
      dap.pause(id)
    end
  end)
end

local function select_frame(frame)
  local session = require("dap").session()
  if session and session.stopped_thread_id and frame then
    session:_frame_set(frame)
  end
end

local function stack_buffer()
  if stack_buf and api.nvim_buf_is_valid(stack_buf) then
    return stack_buf
  end
  stack_buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_name(stack_buf, "dap-callstack")
  vim.bo[stack_buf].bufhidden = "hide"
  vim.bo[stack_buf].modifiable = false
  vim.bo[stack_buf].filetype = "dap_callstack"
  for _, key in ipairs({ "<CR>", "<2-LeftMouse>" }) do
    vim.keymap.set("n", key, function()
      select_frame(line_frames[api.nvim_win_get_cursor(0)[1]])
    end, { buffer = stack_buf, desc = "Go to this frame" })
  end
  return stack_buf
end

-- what the debugger is doing, shown on the console's title bar and in the
-- stack pane: idle, running, paused (and why) or finished (exit code)
local status = { kind = "idle" }

local function escape(text)
  return (tostring(text or ""):gsub("%%", "%%%%"))
end

-- the console's winbar after its title (config/dap_panels.lua); a narrow
-- console cuts the details after the state (%<), never the state itself
function M.status_bar()
  if status.kind == "running" then
    return "%#DapStatusRunning# ● running %#DapPanelBar#%< " .. escape(status.name)
  elseif status.kind == "paused" then
    local session = require("dap").session()
    local frame = session and session.current_frame
    local at = frame and (frame.name .. "  " .. M.frame_location(frame)) or ""
    return "%#DapStatusPaused# ⏸ paused %#DapPanelBar#%< " .. escape(status.reason) .. " · " .. escape(at)
  elseif status.kind == "finished" then
    return (status.failed and "%#DapStatusFailed#" or "%#DapStatusEnded#")
      .. " ■ "
      .. status.outcome
      .. " %#DapPanelBar#%< "
      .. escape(status.name)
      .. "   ,l reruns"
  end
  return "%#DapStatusEnded# not debugging %#DapPanelBar# ,c starts"
end

local ns = api.nvim_create_namespace("dap_callstack")

function M.render()
  if not (stack_buf and api.nvim_buf_is_valid(stack_buf)) then
    return
  end
  local session = require("dap").session()
  local lines, marks, current_line = {}, {}, nil
  line_frames = {}
  if not session then
    lines = {
      status.kind == "finished" and ("  " .. status.outcome) or "  not debugging",
    }
  elseif not session.stopped_thread_id then
    lines = { "  running…" }
  else
    for _, frame in ipairs(M.frames(session)) do
      local current = session.current_frame and frame.id == session.current_frame.id
      local name = (current and "▶ " or "  ") .. frame.name
      lines[#lines + 1] = name .. "  " .. M.frame_location(frame)
      line_frames[#lines] = frame
      local subtle = frame.presentationHint == "subtle" or frame.presentationHint == "label"
      marks[#marks + 1] =
        { #lines - 1, 0, #name, current and "DapCallstackCurrent" or subtle and "Comment" or "Function" }
      marks[#marks + 1] = { #lines - 1, #name + 2, #lines[#lines], "Comment" }
      if current then
        current_line = #lines
      end
    end
    if #lines == 0 then
      lines = { "  no frames" }
    end
  end
  vim.bo[stack_buf].modifiable = true
  api.nvim_buf_set_lines(stack_buf, 0, -1, false, lines)
  vim.bo[stack_buf].modifiable = false
  api.nvim_buf_clear_namespace(stack_buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    api.nvim_buf_set_extmark(stack_buf, ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
  end
  if current_line then
    api.nvim_buf_set_extmark(stack_buf, ns, current_line - 1, 0, { line_hl_group = "DapStoppedLine" })
    if stack_win and api.nvim_win_is_valid(stack_win) then
      api.nvim_win_set_cursor(stack_win, { current_line, 0 })
    end
  end
end

function M.is_open()
  return find_win("dap-repl") ~= nil or (stack_win ~= nil and api.nvim_win_is_valid(stack_win))
end

function M.open()
  local prev = api.nvim_get_current_win()
  local console = find_win("dap-repl")
  if not console then
    require("dap").repl.open({ height = HEIGHT }, "botright split")
    console = find_win("dap-repl")
  end
  if not console then
    return
  end
  vim.wo[console].winfixheight = true
  vim.wo[console].winfixbuf = true
  if not (stack_win and api.nvim_win_is_valid(stack_win)) then
    stack_win = api.nvim_open_win(stack_buffer(), false, {
      split = "right",
      win = console,
      width = math.floor(vim.o.columns * STACK_WIDTH),
    })
    for option, value in pairs({
      number = false,
      relativenumber = false,
      signcolumn = "no",
      foldcolumn = "0",
      wrap = false,
      cursorline = false,
      winfixheight = true,
      winfixwidth = true,
      winfixbuf = true,
    }) do
      vim.wo[stack_win][0][option] = value
    end
  end
  if api.nvim_win_is_valid(prev) then
    api.nvim_set_current_win(prev)
  end
  M.render()
end

function M.close()
  if stack_win and api.nvim_win_is_valid(stack_win) then
    api.nvim_win_close(stack_win, true)
  end
  stack_win = nil
  -- "toggle" only hides the console; a plain close() deletes its buffer
  require("dap").repl.close({ mode = "toggle" })
end

function M.toggle()
  if M.is_open() then
    M.close()
  else
    M.open()
  end
end

-- the code window you were last in, else the biggest one
local function last_code_win()
  if code_win and is_code_win(code_win) and api.nvim_win_get_tabpage(code_win) == api.nvim_get_current_tabpage() then
    return code_win
  end
  local best, area = nil, 0
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    local size = api.nvim_win_get_width(win) * api.nvim_win_get_height(win)
    if is_code_win(win) and size > area then
      best, area = win, size
    end
  end
  return best
end

-- the window you're in if it shows code, else the code window you were last in
function M.code_win()
  local current = api.nvim_get_current_win()
  return is_code_win(current) and current or last_code_win()
end

function M.switchbuf(bufnr, line, column)
  local current = api.nvim_get_current_win()
  local target
  for _, win in ipairs(api.nvim_tabpage_list_wins(0)) do
    if api.nvim_win_get_buf(win) == bufnr and is_code_win(win) then
      target = win
      break
    end
  end
  if not target and is_code_win(current) then
    target = current
  end
  target = target or last_code_win()
  if not target then -- no code window left: a new one above the bottom row
    target = api.nvim_open_win(bufnr, false, { split = "above", win = -1 })
  end
  api.nvim_win_set_buf(target, bufnr)
  pcall(api.nvim_win_set_cursor, target, { line, math.max(column - 1, 0) })
  api.nvim_win_call(target, function()
    vim.cmd("normal! zv")
  end)
  -- the cursor goes to the code, unless you're in the console or the stack
  if not is_panel(api.nvim_win_get_buf(current)) then
    api.nvim_set_current_win(target)
  end
end

-- back to the arrow (the frame it's paused in, or the one ,k / ,j moved to)
-- from anywhere: the console, the stack pane, another file (,g)
function M.goto_current()
  local session = require("dap").session()
  local frame = session and session.stopped_thread_id and session.current_frame
  if not frame then
    return vim.notify("not paused", vim.log.levels.INFO)
  end
  -- from a panel the jump would leave the cursor there: go to the code first
  if not is_code_win(api.nvim_get_current_win()) then
    local win = last_code_win()
    if win then
      api.nvim_set_current_win(win)
    end
  end
  session:_frame_set(frame)
end

local function highlights()
  local fn = api.nvim_get_hl(0, { name = "Function", link = false })
  api.nvim_set_hl(0, "DapCallstackCurrent", { fg = fn.fg, bold = true })
end

function M.setup()
  local dap = require("dap")
  dap.defaults.fallback.switchbuf = M.switchbuf
  highlights()
  local group = api.nvim_create_augroup("dap_layout", { clear = true })
  api.nvim_create_autocmd("ColorScheme", { group = group, callback = highlights })
  api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
      local win = api.nvim_get_current_win()
      if is_code_win(win) then
        code_win = win
      end
    end,
  })
  -- frames arrive (a stop), the frame changes (its scopes are fetched on
  -- every ,k / ,j / Enter), the program runs or ends
  local function rerender()
    vim.schedule(function()
      M.render()
      vim.cmd("redrawstatus!") -- the console's status
    end)
  end
  dap.listeners.after.event_initialized["dap_layout"] = function(session)
    status = { kind = "running", name = session.config.name }
    vim.schedule(M.open)
    rerender()
  end
  dap.listeners.after.event_continued["dap_layout"] = function(session)
    status = { kind = "running", name = session.config.name }
    rerender()
  end
  dap.listeners.after.event_stopped["dap_layout"] = function(session, body)
    status = { kind = "paused", reason = body.reason, name = session.config.name }
    rerender()
  end
  dap.listeners.after.stackTrace["dap_layout"] = rerender
  dap.listeners.after.scopes["dap_layout"] = rerender

  -- the end of a run, said like PyCharm does in the console, as a
  -- notification, and on the console's bar until the next run
  local exit_codes, terminated, reported = {}, {}, {}
  dap.listeners.after.event_exited["dap_layout"] = function(session, body)
    exit_codes[session.id] = body.exitCode
  end
  -- ,q: the program is killed, so its exit code says nothing about it
  dap.listeners.before.terminate["dap_layout"] = function(session)
    terminated[session.id] = true
  end
  for _, event in ipairs({ "event_terminated", "disconnect" }) do
    dap.listeners.after[event]["dap_layout"] = function(session)
      vim.defer_fn(function() -- once dap.session() has moved on
        -- a child session (a subprocess) ending isn't the end of the run
        if dap.session() or reported[session.id] then
          return rerender()
        end
        reported[session.id] = true
        local code = not terminated[session.id] and exit_codes[session.id] or nil
        local failed = code ~= nil and code ~= 0
        status = {
          kind = "finished",
          outcome = terminated[session.id] and "terminated" or code and ("finished · exit code " .. code) or "ended",
          failed = failed,
          name = session.config.name,
        }
        local text = terminated[session.id] and "Process terminated"
          or code and ("Process finished with exit code " .. code)
          or "Debug session ended"
        require("dap.repl").append(text)
        vim.notify(text, failed and vim.log.levels.WARN or vim.log.levels.INFO, { title = session.config.name })
        rerender()
      end, 100)
    end
  end
end

return M
