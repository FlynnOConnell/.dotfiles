-- The debug console and the ,u panels as tinted panels with a title bar.
-- Splits can't have borders (only floats can), so each panel gets a darker
-- background, a " Title " bar in the float border's color and a matching
-- divider instead.
local M = {}

local titles = {
  ["dap-repl"] = "Debug console",
  dapui_scopes = "Variables",
  dapui_stacks = "Call stack",
  dapui_watches = "Watches",
  dapui_breakpoints = "Breakpoints",
  dapui_console = "Program output",
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
end

local function style(buf)
  local title = titles[vim.bo[buf].filetype]
  if not title then
    return
  end
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    if vim.api.nvim_win_get_config(win).relative == "" then -- splits only, not popups
      vim.wo[win].winbar = "%#DapPanelTitle# " .. title .. " %#DapPanelBar#"
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
