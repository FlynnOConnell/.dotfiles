-- Debugger popups, used instead of the dap-ui side panels:
--   summary(expr)  type, shape, dtype, min/max/mean/std of one value (,v)
--   variables()    tree of the variables you defined in this frame (,V)
--   line_values()  tree of the variables on the cursor line (,x)
-- plus one-line briefs for the inline values. All evaluate
-- python/nvim_inspect.py inside the paused program.
local M = {}

local inspect_py = vim.fn.stdpath("config") .. "/python/nvim_inspect.py"

-- names that are IPython's bookkeeping in the REPL's namespace, not yours
local ipython_names = { In = true, Out = true, exit = true, quit = true, get_ipython = true }

local function paused_frame()
  local session = require("dap").session()
  local frame = session and session.current_frame
  if not (session and session.stopped_thread_id and frame) then
    vim.notify("works while the debugger is paused", vim.log.levels.WARN)
    return nil
  end
  return session, frame
end

-- evaluate python in the paused frame; `on_text` gets the resulting string
local function evaluate(session, frame, code, on_text)
  session:request("evaluate", { expression = code, frameId = frame.id, context = "clipboard" }, function(err, resp)
    if err then
      return on_text(nil, err.message or vim.inspect(err))
    end
    local text = resp.result
    -- the result comes back as a python string literal: unquote it
    local quote = text:sub(1, 1)
    if (quote == "'" or quote == '"') and text:sub(-1) == quote then
      text = text:sub(2, -2):gsub("\\(.)", { n = "\n", t = "\t", ["\\"] = "\\", ["'"] = "'", ['"'] = '"' })
    end
    on_text(text)
  end)
end

local function call_inspect(fn, arg)
  return string.format("__import__('runpy').run_path(%q)[%q](%s)", inspect_py, fn, arg)
end

function M.summary(expr)
  local session, frame = paused_frame()
  if not session then
    return
  end
  evaluate(session, frame, call_inspect("summarize", expr), function(text, err)
    vim.lsp.util.open_floating_preview(vim.split(text or ("error: " .. err), "\n"), "", {
      border = "rounded",
      title = " " .. expr .. " ",
      focus_id = "dap_value_summary",
    })
  end)
end

-- debugpy's groupings and plumbing a variables view doesn't need
local hidden_types = { module = true, method = true, ["builtin_function_or_method"] = true, ["function"] = true }
local function shown(var)
  return not var.name:match(" variables$")
    and not var.name:match("^_")
    and not ipython_names[var.name]
    and not hidden_types[var.type or ""]
end

local array_types = { ndarray = true, Tensor = true, Parameter = true, memmap = true, MaskedArray = true }
local function wants_brief(var)
  return var.type
    and (array_types[var.type] or var.type:match("Array$") or (var.value or ""):match("^<.* at 0x%x+>$"))
end

-- evaluate one-line briefs for the nodes that need one, keyed by expression
local function fill_node_briefs(session, frame, nodes, done)
  local exprs = {}
  for _, node in ipairs(nodes) do
    if not node.brief and wants_brief(node.var) and node.expr then
      exprs[#exprs + 1] = node.expr
    end
  end
  if #exprs == 0 then
    return done()
  end
  local namespace = "{" .. table.concat(vim.tbl_map(function(e)
    return string.format("%q: (%s)", e, e)
  end, exprs), ", ") .. "}"
  evaluate(session, frame, call_inspect("briefs", namespace), function(text)
    local found = {}
    for line in (text or ""):gmatch("[^\n]+") do
      local expr, desc = line:match("^(.-)\t(.*)$")
      if expr then
        found[expr] = desc
      end
    end
    for _, node in ipairs(nodes) do
      node.brief = node.brief or found[node.expr]
    end
    done()
  end)
end

-- debugpy's values are python reprs; read the common numpy ones plainly
local function tidy(node)
  if node.brief then
    return node.brief
  end
  local value = (node.var.value or ""):gsub("%s+", " ")
  local from, to = node.name:match("^%[(%d+):(%d+)%]$") -- an array's element range
  if from then
    return (tonumber(to) - tonumber(from)) .. " items"
  end
  value = value:gsub("^np%.[%w_]+%((.*)%)$", "%1") -- np.float32(15.06) -> 15.06
  value = value:gsub("^dtype%('(.-)'%)$", "%1") -- dtype('float32') -> float32
  return value
end

local function make_nodes(vars, depth)
  local nodes = {}
  for _, var in ipairs(vars) do
    if shown(var) then
      -- debugpy names an array's element range "[0:300] ", trailing space included
      local name = vim.trim(var.name)
      nodes[#nodes + 1] = { var = var, name = name, expr = var.evaluateName or name, depth = depth }
    end
  end
  return nodes
end

-- A tree popup: one line per value, <CR>/l/o expands (array min/max/shape
-- and elements, object attributes), h collapses, s summary, q closes.
local function open_tree(session, frame, roots, title)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local ns = vim.api.nvim_create_namespace("dap_tree")
  local width = math.min(110, vim.o.columns - 8)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = 1,
    row = 3,
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
    footer = " <CR> expand · h collapse · s summary · m viewer · q close ",
    footer_pos = "center",
    style = "minimal",
  })
  vim.wo[win].cursorline = true
  vim.wo[win].wrap = false

  local visible = {}
  local function render()
    visible = {}
    local function walk(nodes)
      for _, node in ipairs(nodes) do
        visible[#visible + 1] = node
        if node.expanded and node.children then
          walk(node.children)
        end
      end
    end
    walk(roots)
    local name_width = 0
    for _, node in ipairs(visible) do
      name_width = math.max(name_width, node.depth * 2 + vim.fn.strdisplaywidth(node.name))
    end
    name_width = math.min(name_width, 40)
    local lines, marks = {}, {}
    for i, node in ipairs(visible) do
      local icon = node.var.variablesReference > 0 and (node.expanded and "▾ " or "▸ ") or "  "
      local indent = string.rep("  ", node.depth)
      local value = tidy(node)
      local left = indent .. icon .. node.name
      local pad = math.max(1, name_width + 2 - vim.fn.strdisplaywidth(indent .. node.name))
      local line = " " .. left .. string.rep(" ", pad + 1) .. value
      if vim.fn.strdisplaywidth(line) > width then
        line = vim.fn.strcharpart(line, 0, width - 1) .. "…"
      end
      lines[i] = line
      local name_start = 1 + #indent + #icon
      marks[i] = { icon = { 1 + #indent, name_start }, name = { name_start, name_start + #node.name }, value = name_start + #node.name }
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for i, m in ipairs(marks) do
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, m.icon[1], { end_col = m.icon[2], hl_group = "Comment" })
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, m.name[1], { end_col = m.name[2], hl_group = "Identifier" })
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, m.value, { end_row = i, end_col = 0, hl_group = "Special", strict = false })
    end
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_height(win, math.max(1, math.min(#lines, vim.o.lines - 10)))
    end
  end

  local function current()
    return visible[vim.api.nvim_win_get_cursor(win)[1]]
  end
  local function expand()
    local node = current()
    if not node or node.var.variablesReference == 0 then
      return
    end
    if node.expanded then
      node.expanded = false
      return render()
    end
    if node.children then
      node.expanded = true
      return render()
    end
    session:request("variables", { variablesReference = node.var.variablesReference }, function(err, resp)
      if err or not resp then
        return
      end
      node.children = make_nodes(resp.variables, node.depth + 1)
      node.expanded = true
      fill_node_briefs(session, frame, node.children, function()
        if vim.api.nvim_buf_is_valid(buf) then
          render()
        end
      end)
    end)
  end
  local function collapse()
    local node = current()
    if not node then
      return
    end
    if node.expanded then
      node.expanded = false
      return render()
    end
    -- jump to the parent
    local row = vim.api.nvim_win_get_cursor(win)[1]
    for i = row - 1, 1, -1 do
      if visible[i].depth < node.depth then
        return vim.api.nvim_win_set_cursor(win, { i, 0 })
      end
    end
  end

  local opts = { buffer = buf, nowait = true }
  for _, k in ipairs({ "<CR>", "l", "o" }) do
    vim.keymap.set("n", k, expand, opts)
  end
  vim.keymap.set("n", "h", collapse, opts)
  vim.keymap.set("n", "s", function()
    local node = current()
    if node then
      M.summary(node.expr)
    end
  end, opts)
  vim.keymap.set("n", "m", function()
    local node = current()
    if node then
      require("sciview").show(node.expr)
    end
  end, opts)
  vim.keymap.set("n", "q", "<cmd>close<cr>", opts)
  vim.keymap.set("n", "<Esc>", "<cmd>close<cr>", opts)

  fill_node_briefs(session, frame, roots, function()
    if vim.api.nvim_buf_is_valid(buf) then
      render()
    end
  end)
end

-- the variables of the paused frame's first scope (Locals), then `pick`
local function frame_variables(pick)
  local session, frame = paused_frame()
  if not session then
    return
  end
  session:request("scopes", { frameId = frame.id }, function(err, resp)
    local scope = not err and resp.scopes[1]
    if not scope then
      return vim.notify("no variables in this frame", vim.log.levels.WARN)
    end
    session:request("variables", { variablesReference = scope.variablesReference }, function(err2, vars)
      if not err2 then
        pick(session, frame, vars.variables)
      end
    end)
  end)
end

-- values whose debugpy children are noise in an explorer: numbers (numpy
-- scalars too), strings, tuples like shapes, dtypes, devices, plain arrays
local leaf_types = { int = true, float = true, complex = true, bool = true, str = true, bytes = true,
  tuple = true, NoneType = true, dtype = true, device = true }
local function leaf_type(t)
  return array_types[t] or leaf_types[t] or t:match("^u?int%d*$") or t:match("^float%d*$")
    or t:match("^complex%d*$") or t:match("^bool_?$") or t:match("DType$") ~= nil
end

-- one row per variable for the sciview explorer (~/repos/sciview/nvim/lua/sciview/init.lua):
-- { name, expr, type, value, brief, array, expandable }. `array` rows can be
-- sent to the viewer; `expandable` ones (objects, lists, dicts) have
-- children, fetched by evaluating `expr` again (M.children_listing).
local function listing_rows(session, frame, vars, top, cb)
  local nodes = make_nodes(vars, 0)
  fill_node_briefs(session, frame, nodes, function()
    cb(vim.tbl_map(function(node)
      local brief = node.brief
      local is_array = brief ~= nil and brief:match("%s%([%d%)]") ~= nil -- " (300, 32, 32)"
      -- frame variables are their own expression; children need evaluateName
      local refable = top or node.var.evaluateName ~= nil
      return {
        name = node.name,
        expr = node.expr,
        type = node.var.type or "",
        value = tidy(node):sub(1, 200),
        brief = brief,
        array = is_array and refable,
        -- numpy arrays and tensors expand into debugpy internals: leaves. Lazy
        -- array classes (CompressionArray, ...) are both: openable and sendable
        expandable = refable and node.var.variablesReference > 0 and not leaf_type(node.var.type or ""),
      }
    end, nodes))
  end)
end

-- the variables you defined in `frame`
function M.frame_listing(session, frame, cb)
  session:request("scopes", { frameId = frame.id }, function(err, resp)
    local scope = not err and resp and resp.scopes[1]
    if not scope then
      return cb({})
    end
    session:request("variables", { variablesReference = scope.variablesReference }, function(err2, vars)
      if err2 or not vars then
        return cb({})
      end
      listing_rows(session, frame, vars.variables, true, cb)
    end)
  end)
end

-- the attributes / items of the value of `expr` in `frame`
function M.children_listing(session, frame, expr, cb)
  session:request("evaluate", { expression = expr, frameId = frame.id, context = "watch" }, function(err, resp)
    if err or not resp or (resp.variablesReference or 0) == 0 then
      return cb({}, err and (err.message or "error") or "no attributes")
    end
    session:request("variables", { variablesReference = resp.variablesReference }, function(err2, vars)
      if err2 or not vars then
        return cb({}, "could not list")
      end
      -- children's evaluateName is relative to nothing when debugpy omits it;
      -- build it from the parent so they can be expanded / sent in turn
      for _, var in ipairs(vars.variables) do
        if not var.evaluateName and var.name:match("^[%a_][%w_]*$") then
          var.evaluateName = expr .. "." .. var.name
        end
      end
      listing_rows(session, frame, vars.variables, false, cb)
    end)
  end)
end

function M.variables()
  frame_variables(function(session, frame, vars)
    local roots = make_nodes(vars, 0)
    if #roots == 0 then
      return vim.notify("nothing defined in this frame yet", vim.log.levels.INFO)
    end
    open_tree(session, frame, roots, frame.name)
  end)
end

-- Inline values (nvim-dap-virtual-text) show debugpy's repr, which for an
-- array is a truncated printout. When a frame's scopes are fetched, evaluate
-- one-line briefs ("ndarray (300, 32, 32) float32") for its array-like and
-- object values and redraw; lua/plugins/dap-virtual-text.lua reads them here.
M.briefs = {} -- frameId -> { name -> brief }

local function fill_briefs(session, frame_id, scope)
  session:request("variables", { variablesReference = scope.variablesReference }, function(err, vars)
    if err or not vars then
      return
    end
    local names = {}
    for _, var in ipairs(vars.variables) do
      if shown(var) and wants_brief(var) then
        names[#names + 1] = var.name
      end
    end
    M.briefs[frame_id] = M.briefs[frame_id] or {}
    if #names == 0 then
      return
    end
    local namespace = "{" .. table.concat(vim.tbl_map(function(n)
      return string.format("%q: %s", n, n)
    end, names), ", ") .. "}"
    evaluate(session, { id = frame_id }, call_inspect("briefs", namespace), function(text)
      if not text then
        return
      end
      for line in text:gmatch("[^\n]+") do
        local name, desc = line:match("^(.-)\t(.*)$")
        if name then
          M.briefs[frame_id][name] = desc
        end
      end
      pcall(function()
        require("nvim-dap-virtual-text").refresh()
      end)
    end)
  end)
end

function M.setup_inline_briefs()
  local dap = require("dap")
  dap.listeners.after.scopes["inline_briefs"] = function(session, err, resp, request)
    local frame_id = request and request.frameId
    if err or not resp or not frame_id or M.briefs[frame_id] or not resp.scopes[1] then
      return
    end
    M.briefs[frame_id] = {}
    fill_briefs(session, frame_id, resp.scopes[1])
  end
  -- values change once the program runs again
  dap.listeners.after.event_continued["inline_briefs"] = function()
    M.briefs = {}
  end
  dap.listeners.after.event_terminated["inline_briefs"] = function()
    M.briefs = {}
  end
end

-- ,x: a tree of every variable on the cursor line (the ones the
-- inline values show), each expandable like in ,V.
function M.line_values()
  local line, row = vim.api.nvim_get_current_line(), vim.api.nvim_win_get_cursor(0)[1]
  frame_variables(function(session, frame, vars)
    local by_name = {}
    for _, var in ipairs(vars) do
      by_name[var.name] = var
    end
    local picked, seen = {}, {}
    for word in line:gmatch("[%a_][%w_]*") do
      if by_name[word] and not seen[word] then
        seen[word] = true
        picked[#picked + 1] = by_name[word]
      end
    end
    local roots = make_nodes(picked, 0)
    if #roots == 0 then
      return vim.notify("no variables on this line", vim.log.levels.INFO)
    end
    open_tree(session, frame, roots, "line " .. row)
  end)
end

return M
