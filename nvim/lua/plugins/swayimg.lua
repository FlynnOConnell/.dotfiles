-- Images open in a swayimg window, not as text (config/swayimg.lua). In
-- neo-tree, Enter on an image leaves the editor window as it is, and the P
-- preview sends each image the cursor lands on.
return {
  "nvim-neo-tree/neo-tree.nvim",
  init = function()
    require("config.swayimg").setup()
  end,
  opts = function(_, opts)
    local swayimg = require("config.swayimg")
    opts.event_handlers = opts.event_handlers or {}
    vim.list_extend(opts.event_handlers, {
      {
        event = "file_open_requested",
        handler = function(args)
          if swayimg.is_image(args.path) then
            swayimg.open(args.path)
            return { handled = true }
          end
        end,
      },
      {
        event = "neo_tree_preview_before_render",
        handler = function(args)
          local path = vim.api.nvim_buf_get_name(args.bufnr)
          if swayimg.is_image(path) then
            swayimg.open(path)
          end
        end,
      },
    })
  end,
}
