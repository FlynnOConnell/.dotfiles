-- ,dd: saved run commands per project, debugged with <CR>. The popup is a
-- plain buffer, one command per line: `dd` deletes, `yyp` copies, edit args
-- in place; it's saved when closed. A line is what you'd type in a shell:
--   masknmf run --pipeline two-photon-calcium movie.tif --fs 30   (an env command)
--   scripts/foo.py --n 3                                          (a file)
--   -m package.module --flag                                      (a module)
-- Lines starting with # are notes. Stored per project root in
-- stdpath("data")/run_configs.json, not in the repo.
local M = {}

local STORE = vim.fn.stdpath("data") .. "/run_configs.json"
local HINT = "one command per line, e.g.  masknmf run --pipeline two-photon-calcium movie.tif --fs 30"
local ns = vim.api.nvim_create_namespace("run_configs")

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

local function debug_line(line, root)
  local args = split(line)
  if #args == 0 then
    return
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
  if first == "-m" then
    config.module = table.remove(args, 1)
  else
    -- a command installed in the env (masknmf, pytest, ...) is a python script
    local venv = vim.env.VIRTUAL_ENV
    local command = venv and venv .. "/bin/" .. first
    config.program = (not first:find("/") and command and vim.uv.fs_stat(command)) and command or first
  end
  config.args = args
  require("dap").run(config)
end

function M.open()
  local root = project_root()
  local store = read_store()
  local lines = store[root] or { "" }

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].syntax = "sh" -- highlights flags and quoted paths (no filetype: no LSP)
  vim.bo[buf].formatoptions = "" -- `o` on a # note doesn't start another
  -- a faint example while the list is empty
  local function hint()
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    local current = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if #current == 1 and current[1] == "" then
      vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, { virt_text = { { HINT, "Comment" } }, virt_text_pos = "overlay" })
    end
  end
  hint()
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, { buffer = buf, callback = hint })
  local width = math.floor(vim.o.columns * 0.7)
  local height = math.max(math.min(#lines + 2, math.floor(vim.o.lines * 0.5)), 5)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " Run configs: " .. vim.fn.fnamemodify(root, ":t") .. " ",
    title_pos = "center",
    footer = " <CR> debug  dd delete  yyp copy  q close ",
    footer_pos = "right",
  })
  vim.wo[win].cursorline = true
  -- start on the first command, not the help line
  for i, line in ipairs(lines) do
    if not line:match("^%s*#") and line:match("%S") then
      vim.api.nvim_win_set_cursor(win, { i, 0 })
      break
    end
  end

  local function save()
    local kept = vim.tbl_filter(function(l)
      return l:match("%S") ~= nil
    end, vim.api.nvim_buf_get_lines(buf, 0, -1, false))
    local data = read_store()
    data[root] = #kept > 0 and kept or nil
    write_store(data)
  end
  local function close()
    save()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  local map = function(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true })
  end
  map("q", close)
  map("<Esc>", close)
  map("<CR>", function()
    local line = vim.api.nvim_get_current_line()
    if line:match("^%s*#") or not line:match("%S") then
      return
    end
    close()
    debug_line(line, root)
  end)
  vim.api.nvim_create_autocmd("WinLeave", { buffer = buf, once = true, callback = close })
end

return M
