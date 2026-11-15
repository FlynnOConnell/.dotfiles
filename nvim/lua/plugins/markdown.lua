-- Markdown is edited as plain text and previewed in a Chrome app window styled
-- like VS Code's preview (markdown-preview/*.css), live-updating and
-- scroll-synced. The window lives on Hyprland's special:markdown-preview on
-- every machine looking at this nvim, over ssh too (config/markdown_preview.lua).
-- It starts hidden with the first markdown buffer and follows whichever one is
-- current; SUPER+N switches between editor and preview from either side,
-- <leader>cp shows it from nvim.
local dir_css = vim.fn.stdpath("config") .. "/markdown-preview"

local function show_preview()
  require("config.markdown_preview").show()
end

return {
  { "MeanderingProgrammer/render-markdown.nvim", enabled = false },
  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    keys = {
      { "<leader>cp", show_preview, ft = "markdown", desc = "Markdown Preview" },
    },
    init = function()
      -- NOTE: the plugin's node server calls this by name over RPC, which
      -- can't reach a Lua function, so it has to be a Vimscript one.
      vim.cmd([[
        function! MkdpOpenAppWindow(url) abort
          call v:lua.require'config.markdown_preview'.open(a:url)
        endfunction
      ]])
      vim.g.mkdp_browserfunc = "MkdpOpenAppWindow"
      vim.g.mkdp_markdown_css = dir_css .. "/markdown.css"
      vim.g.mkdp_highlight_css = dir_css .. "/highlight.css"
      vim.g.mkdp_theme = "dark"
      vim.g.mkdp_page_title = "${name}"
      -- one window follows whichever markdown buffer is current, and stays
      -- open (hidden or not) when the buffer is left
      vim.g.mkdp_auto_start = 1
      vim.g.mkdp_auto_close = 0
      vim.g.mkdp_combine_preview = 1
      vim.g.mkdp_combine_preview_auto_refresh = 1
      vim.g.mkdp_preview_options = {
        mkit = vim.empty_dict(),
        katex = vim.empty_dict(),
        uml = vim.empty_dict(),
        maid = vim.empty_dict(),
        disable_sync_scroll = 0,
        sync_scroll_type = "middle",
        hide_yaml_meta = 1,
        sequence_diagrams = vim.empty_dict(),
        flowchart_diagrams = vim.empty_dict(),
        content_editable = false,
        disable_filename = 1,
        toc = vim.empty_dict(),
      }
    end,
  },
}
