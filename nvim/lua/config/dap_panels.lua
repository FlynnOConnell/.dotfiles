-- The debug console, the call stack, the program's terminal and the <leader>du panels
-- as tinted panels with a title bar, in colors taken from the colorscheme
-- (again on every change).
-- Splits can't have borders (only floats can), so each panel gets a darker
-- background, a " Title " bar in the float border's color and a matching
-- divider instead.
local M = {}

local titles = {
  ["dap-repl"] = "Debug console",
  dap_callstack = "Call stack",
  dapui_scopes = "Variables",
  dapui_stacks = "Call stack",
  dapui_watches = "Watches",
  dapui_breakpoints = "Breakpoints",
  dapui_console = "Program output",
  ["dap-terminal"] = "Program",
}

local function highlights()
  local function hl(name)
    return vim.api.nvim_get_hl(0, { name = name, link = false })
  end
  local raised = hl("CursorLine").bg or 0x292e42
  local function scale(c, f)
    local r, g, b = math.floor(c / 65536), math.floor(c / 256) % 256, c % 256
    return math.floor(r * f) * 65536 + math.floor(g * f) * 256 + math.floor(b * f)
  end
  local panel = scale(raised, 0.72)
  local accent = hl("FloatBorder").fg or hl("Function").fg
  vim.api.nvim_set_hl(0, "DapPanel", { bg = panel })
  vim.api.nvim_set_hl(0, "DapPanelBar", { bg = panel })
  vim.api.nvim_set_hl(0, "DapPanelTitle", { fg = panel, bg = accent, bold = true })
  vim.api.nvim_set_hl(0, "DapPanelSeparator", { fg = accent })
  -- the debugger's state on the console's bar (config/dap_layout.lua)
  for state, from in pairs({ Running = "DiagnosticWarn", Paused = "DiagnosticOk", Failed = "DiagnosticError", Ended = "Comment" }) do
    vim.api.nvim_set_hl(0, "DapStatus" .. state, { fg = hl(from).fg, bg = panel, bold = state ~= "Ended" })
  end
end

-- after the title: the console's and the program's bars also say what the
-- debugger is doing
local status_bar = " %{%v:lua.require'config.dap_layout'.status_bar()%}"
local status = { ["dap-repl"] = status_bar, ["dap-terminal"] = status_bar }

local function style(buf)
  local title = titles[vim.bo[buf].filetype]
  if not title then
    return
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_get_config(win).relative == "" then -- splits only, not popups
      vim.wo[win].winbar = "%#DapPanelTitle# " .. title .. " %#DapPanelBar#" .. (status[vim.bo[buf].filetype] or "")
      vim.wo[win].winhighlight = table.concat({
        "Normal:DapPanel",
        "NormalNC:DapPanel",
        "EndOfBuffer:DapPanel",
        "SignColumn:DapPanel",
        "WinBar:DapPanelBar",
        "WinBarNC:DapPanelBar",
        "WinSeparator:DapPanelSeparator",
      }, ",")
    end
  end
end

function M.setup()
  highlights()
  local group = vim.api.nvim_create_augroup("dap_panels", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = highlights })
  vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    group = group,
    callback = function(ev)
      -- the window may not be showing the buffer yet when FileType fires
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(ev.buf) then
          style(ev.buf)
        end
      end)
    end,
  })
end

return M
