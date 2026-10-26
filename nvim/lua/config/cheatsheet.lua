-- Curated keybind cheatsheet, drawn as a formatted panel in a float.
-- Source is <config>/cheatsheet.md (## sections + | key | action | alt | tables).
-- In the panel: `e` edits the source, `q`/<Esc> closes.
local M = {}

local path = vim.fn.stdpath("config") .. "/cheatsheet.md"
local ns = vim.api.nvim_create_namespace("cheatsheet")
local win = nil

-- derive colors from the active theme so omarchy theme switches keep working
local function set_highlights()
  local function hl(name)
    return vim.api.nvim_get_hl(0, { name = name, link = false })
  end
  local cap_bg = hl("CursorLine").bg or hl("Visual").bg
  vim.api.nvim_set_hl(0, "CheatsheetKey", { fg = hl("Special").fg, bg = cap_bg, bold = true })
  vim.api.nvim_set_hl(0, "CheatsheetSection", { fg = hl("Title").fg, bold = true })
  vim.api.nvim_set_hl(0, "CheatsheetRule", { fg = hl("Comment").fg })
  vim.api.nvim_set_hl(0, "CheatsheetAlt", { fg = hl("Comment").fg, italic = true })
  vim.api.nvim_set_hl(0, "CheatsheetHint", { fg = hl("Comment").fg })
end

-- `<leader>ff` -> "SPC f f", `<C-o>` -> "Ctrl-o"
local function pretty_key(chunk)
  local out, i = {}, 1
  while i <= #chunk do
    local tok = chunk:match("^<[^>]+>", i)
    if tok then
      if tok:lower() == "<leader>" then
        out[#out + 1] = "SPC"
      else
        out[#out + 1] = (tok:gsub("^<C%-(.+)>$", "Ctrl-%1"):gsub("^<(.+)>$", "%1"))
      end
      i = i + #tok
    else
      local c = chunk:sub(i, i)
      if c ~= " " then
        out[#out + 1] = c
      end
      i = i + 1
    end
  end
  return table.concat(out, " ")
end

local function key_caps(cell)
  local caps = {}
  for chunk in cell:gmatch("`([^`]+)`") do
    caps[#caps + 1] = " " .. pretty_key(chunk) .. " "
  end
  if #caps == 0 and cell ~= "" then
    caps[1] = " " .. cell .. " "
  end
  return caps
end

local function parse()
  local sections, hint, cur, header_seen = {}, nil, nil, false
  for line in io.lines(path) do
    local title = line:match("^##%s+(.+)")
    if title then
      cur = { title = title, rows = {} }
      sections[#sections + 1] = cur
      header_seen = false
    elseif cur and line:match("^%s*|") then
      if not line:match("^%s*|[%s:|%-]+|%s*$") then
        local cells = {}
        for cell in line:gmatch("|([^|]*)") do
          cells[#cells + 1] = vim.trim(cell)
        end
        if header_seen then
          cur.rows[#cur.rows + 1] = { caps = key_caps(cells[1] or ""), action = cells[2] or "", alt = cells[3] or "" }
        else
          header_seen = true
        end
      end
    elseif not cur and line:match("^`") then
      hint = (line:gsub("`", ""))
    end
  end
  return sections, hint
end

local width = vim.fn.strdisplaywidth

-- each rendered line is { text = string, hls = { { start_byte, end_byte, group } } }
local function render_section(sec, kw, aw, block_w)
  local lines = {}
  lines[#lines + 1] = { text = " " .. sec.title, hls = { { 1, 1 + #sec.title, "CheatsheetSection" } } }
  local rule = " " .. string.rep("─", block_w - 2)
  lines[#lines + 1] = { text = rule, hls = { { 1, #rule, "CheatsheetRule" } } }
  for _, row in ipairs(sec.rows) do
    local text, hls = " ", {}
    for j, cap in ipairs(row.caps) do
      if j > 1 then
        text = text .. " "
      end
      hls[#hls + 1] = { #text, #text + #cap, "CheatsheetKey" }
      text = text .. cap
    end
    text = text .. string.rep(" ", kw - (width(text) - 1)) .. "  " .. row.action
    if row.alt ~= "" then
      text = text .. string.rep(" ", aw - width(row.action)) .. "  "
      hls[#hls + 1] = { #text, #text + #row.alt, "CheatsheetAlt" }
      text = text .. row.alt
    end
    lines[#lines + 1] = { text = text, hls = hls }
  end
  lines[#lines + 1] = { text = "", hls = {} }
  return lines
end

local function build()
  local sections, hint = parse()
  local kw, aw, altw = 0, 0, 0
  for _, sec in ipairs(sections) do
    for _, row in ipairs(sec.rows) do
      kw = math.max(kw, width(table.concat(row.caps, " ")))
      aw = math.max(aw, width(row.action))
      altw = math.max(altw, width(row.alt))
    end
  end
  local block_w = 1 + kw + 2 + aw + (altw > 0 and 2 + altw or 0) + 1
  for _, sec in ipairs(sections) do
    block_w = math.max(block_w, width(sec.title) + 2)
  end

  local blocks, total = {}, 0
  for _, sec in ipairs(sections) do
    local b = render_section(sec, kw, aw, block_w)
    blocks[#blocks + 1] = b
    total = total + #b
  end

  -- two columns when the screen is wide enough, keeping section order
  local gap = "    "
  local cols = { {} }
  if vim.o.columns - 6 >= block_w * 2 + #gap then
    cols[2] = {}
    local left = 0
    for _, b in ipairs(blocks) do
      local target = (left > 0 and left + #b > total / 2 + 2) and cols[2] or cols[1]
      if target == cols[1] then
        left = left + #b
      end
      vim.list_extend(target, b)
    end
  else
    for _, b in ipairs(blocks) do
      vim.list_extend(cols[1], b)
    end
  end

  local out = { { text = "", hls = {} } }
  for i = 1, math.max(#cols[1], cols[2] and #cols[2] or 0) do
    local l = cols[1][i] or { text = "", hls = {} }
    local r = cols[2] and cols[2][i]
    if r then
      local text = l.text .. string.rep(" ", block_w - width(l.text)) .. gap
      local hls = vim.deepcopy(l.hls)
      for _, h in ipairs(r.hls) do
        hls[#hls + 1] = { h[1] + #text, h[2] + #text, h[3] }
      end
      out[#out + 1] = { text = text .. r.text, hls = hls }
    else
      out[#out + 1] = { text = l.text, hls = l.hls }
    end
  end
  while #out > 0 and out[#out].text == "" do
    out[#out] = nil
  end
  if hint then
    out[#out + 1] = { text = "", hls = {} }
    local h = " " .. hint
    out[#out + 1] = { text = h, hls = { { 0, #h, "CheatsheetHint" } } }
  end
  local content_w = (cols[2] and block_w * 2 + #gap or block_w) + 1
  return out, content_w
end

local function draw(buf, lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.tbl_map(function(l)
    return l.text
  end, lines))
  for i, l in ipairs(lines) do
    for _, h in ipairs(l.hls) do
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, h[1], { end_col = h[2], hl_group = h[3] })
    end
  end
end

-- one section (the first whose title starts with `prefix`) drawn into buf as
-- the panel draws it, below plain `header` lines: the image stub
-- (config/swayimg.lua) shows the Images keys this way
function M.draw_section(buf, prefix, header)
  set_highlights()
  local lines = vim.tbl_map(function(text)
    return { text = text, hls = {} }
  end, header or {})
  for _, sec in ipairs((parse())) do
    if vim.startswith(sec.title, prefix) then
      local kw, aw, altw = 0, 0, 0
      for _, row in ipairs(sec.rows) do
        kw = math.max(kw, width(table.concat(row.caps, " ")))
        aw = math.max(aw, width(row.action))
        altw = math.max(altw, width(row.alt))
      end
      local block_w = math.max(1 + kw + 2 + aw + (altw > 0 and 2 + altw or 0) + 1, width(sec.title) + 2)
      vim.list_extend(lines, render_section(sec, kw, aw, block_w))
      break
    end
  end
  draw(buf, lines)
end

function M.toggle()
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
    win = nil
    return
  end
  set_highlights()
  local lines, content_w = build()

  local buf = vim.api.nvim_create_buf(false, true)
  draw(buf, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "cheatsheet"

  local w = math.min(content_w, vim.o.columns - 4)
  local h = math.min(#lines, vim.o.lines - 4)
  win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = w,
    height = h,
    row = math.floor((vim.o.lines - h) / 2) - 1,
    col = math.floor((vim.o.columns - w) / 2),
    border = "rounded",
    title = " Cheatsheet ",
    title_pos = "center",
    style = "minimal",
  })
  vim.wo[win].wrap = false
  vim.wo[win].cursorline = false

  local opts = { buffer = buf, nowait = true }
  vim.keymap.set("n", "q", M.toggle, opts)
  vim.keymap.set("n", "<Esc>", M.toggle, opts)
  vim.keymap.set("n", "e", function()
    M.toggle()
    vim.cmd.edit(vim.fn.fnameescape(path))
  end, opts)
end

return M
