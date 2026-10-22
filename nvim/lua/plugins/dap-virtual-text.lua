-- Inline debugger values, PyCharm-style: at the end of the line instead of
-- wedged into the code, as small raised chips in theme colors (values that
-- just changed turn orange), arrays as "ndarray (300, 32, 32) float32"
-- rather than a truncated printout (briefs from lua/config/dap_popups.lua).
-- ,x expands everything on the cursor line.
local function chip_highlights()
  local function hl(name)
    return vim.api.nvim_get_hl(0, { name = name, link = false })
  end
  -- raised surface: the cursor-line shade, so it reads on the transparent bg
  local chip = hl("CursorLine").bg or hl("Visual").bg
  vim.api.nvim_set_hl(0, "NvimDapVirtualText", { fg = hl("Special").fg, bg = chip })
  vim.api.nvim_set_hl(0, "NvimDapVirtualTextChanged", { fg = hl("Constant").fg, bg = chip, bold = true })
  vim.api.nvim_set_hl(0, "NvimDapVirtualTextError", { fg = hl("DiagnosticError").fg, bg = chip })
  vim.api.nvim_set_hl(0, "NvimDapVirtualTextInfo", { fg = hl("DiagnosticInfo").fg, bg = chip })
end

local MAX_WIDTH = 60

return {
  "theHamsta/nvim-dap-virtual-text",
  opts = {
    virt_text_pos = "eol",
    highlight_changed_variables = true,
    highlight_new_as_changed = false,
    separator = "",
    display_callback = function(variable, _, stackframe)
      local briefs = require("config.dap_popups").briefs[stackframe.id]
      local value = (briefs and briefs[variable.name]) or variable.value:gsub("%s+", " ")
      if vim.fn.strchars(value) > MAX_WIDTH then
        value = vim.fn.strcharpart(value, 0, MAX_WIDTH - 1) .. "…"
      end
      return " " .. variable.name .. " = " .. value .. " "
    end,
  },
  config = function(_, opts)
    require("nvim-dap-virtual-text").setup(opts)
    require("config.dap_popups").setup_inline_briefs()
    chip_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", { callback = chip_highlights })
  end,
}
