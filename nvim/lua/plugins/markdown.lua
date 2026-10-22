-- Higher-contrast markdown rendering. Normal/NormalFloat are transparent
-- (plugin/after/transparency.lua), so the theme's subtle code tint vanished;
-- these groups use solid backgrounds pulled from the active theme instead of
-- hardcoded colors, and are reapplied on every colorscheme change.
local function md_highlights()
  local function hl(name)
    return vim.api.nvim_get_hl(0, { name = name, link = false })
  end
  local card = hl("CursorLine").bg or hl("Visual").bg
  local set = vim.api.nvim_set_hl
  set(0, "RenderMarkdownCode", { bg = card })
  set(0, "RenderMarkdownCodeBorder", { fg = hl("Comment").fg, bg = card })
  set(0, "RenderMarkdownCodeInline", { fg = hl("Constant").fg, bg = card })
  set(0, "RenderMarkdownTableHead", { fg = hl("Title").fg, bold = true })
  set(0, "RenderMarkdownTableRow", { fg = hl("Comment").fg })
end

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      heading = {
        sign = false,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
        width = "block",
        left_pad = 1,
        right_pad = 4,
      },
      code = {
        sign = false,
        style = "full",
        width = "block",
        min_width = 60,
        left_pad = 2,
        right_pad = 2,
        language_pad = 1,
        border = "thin",
        inline_pad = 1,
      },
      pipe_table = { preset = "round" },
      bullet = { icons = { "●", "○", "◆", "◇" } },
      checkbox = {
        enabled = true,
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰄵 " },
        custom = {
          progress = { raw = "[~]", rendered = "󰦖 ", highlight = "RenderMarkdownWarn" },
        },
      },
    },
    init = function()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = md_highlights })
    end,
    config = function(_, opts)
      require("render-markdown").setup(opts)
      md_highlights()
      Snacks.toggle({
        name = "Render Markdown",
        get = require("render-markdown").get,
        set = require("render-markdown").set,
      }):map("<leader>um")
    end,
  },
}
