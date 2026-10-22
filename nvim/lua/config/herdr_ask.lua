-- Send the visual selection, with a question, to a herdr agent.
-- Pick any running agent (any workspace) or spawn a new Claude in a split.
local M = {}

local function herdr(args, on_done)
  vim.system(vim.list_extend({ "herdr" }, args), { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        vim.notify("herdr " .. args[1] .. " " .. (args[2] or "") .. " failed:\n" .. (res.stderr ~= "" and res.stderr or res.stdout), vim.log.levels.ERROR)
        return
      end
      local ok, decoded = pcall(vim.json.decode, res.stdout)
      on_done(ok and decoded.result or {})
    end)
  end)
end

local function herdr_sync(args)
  local res = vim.system(vim.list_extend({ "herdr" }, args), { text = true }):wait()
  if res.code ~= 0 then
    return nil
  end
  local ok, decoded = pcall(vim.json.decode, res.stdout)
  return ok and decoded.result or nil
end

local function selection()
  local s, e = vim.fn.getpos("v"), vim.fn.getpos(".")
  local lines = vim.fn.getregion(s, e, { type = vim.fn.mode() })
  local l1, l2 = math.min(s[2], e[2]), math.max(s[2], e[2])
  return table.concat(lines, "\n"), l1, l2
end

local function build_prompt(question, text, l1, l2)
  local range = l1 == l2 and ("line " .. l1) or ("lines " .. l1 .. "-" .. l2)
  return string.format("%s\n\nFrom `%s` %s:\n```%s\n%s\n```", question, vim.fn.expand("%:p"), range, vim.bo.filetype, text)
end

local function send(target, label, prompt)
  herdr({ "agent", "prompt", target, prompt }, function()
    vim.notify("Sent to " .. label)
  end)
end

local function new_claude(prompt)
  herdr({ "pane", "split", "--pane", vim.env.HERDR_PANE_ID, "--direction", "right", "--cwd", vim.fn.getcwd(), "--no-focus" }, function(r)
    local pane = r.pane.pane_id
    local name = "ask-" .. os.date("%H%M%S")
    vim.notify("Starting Claude in new pane...")
    herdr({ "agent", "start", name, "--kind", "claude", "--pane", pane }, function()
      send(pane, "new Claude (" .. name .. ")", prompt)
    end)
  end)
end

function M.ask()
  if not vim.env.HERDR_PANE_ID then
    return vim.notify("Not running inside herdr", vim.log.levels.WARN)
  end
  local text, l1, l2 = selection()
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)

  local agents = (herdr_sync({ "agent", "list" }) or {}).agents or {}
  local labels = {}
  for _, w in ipairs((herdr_sync({ "workspace", "list" }) or {}).workspaces or {}) do
    labels[w.workspace_id] = w.label
  end

  local choices = { { new = true } }
  for _, a in ipairs(agents) do
    if a.pane_id ~= vim.env.HERDR_PANE_ID then
      table.insert(choices, a)
    end
  end

  vim.ui.select(choices, {
    prompt = "Ask which agent?",
    format_item = function(c)
      if c.new then
        return "+ New Claude (split right)"
      end
      return string.format("%s  ·  %s  [%s]", labels[c.workspace_id] or c.workspace_id, c.terminal_title_stripped or c.agent, c.agent_status)
    end,
  }, function(choice)
    if not choice then
      return
    end
    vim.ui.input({ prompt = "Question: " }, function(question)
      if not question or question == "" then
        return
      end
      local prompt = build_prompt(question, text, l1, l2)
      if choice.new then
        new_claude(prompt)
      else
        send(choice.pane_id, (labels[choice.workspace_id] or "") .. " / " .. (choice.terminal_title_stripped or choice.agent), prompt)
      end
    end)
  end)
end

return M
