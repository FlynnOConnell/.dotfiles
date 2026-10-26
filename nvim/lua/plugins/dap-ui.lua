-- The panels no longer open when debugging starts: the code shows values
-- inline, the bottom row has the console and the call stack
-- (config/dap_layout.lua), and popups cover the rest (<leader>dV variables,
-- <leader>dv one value). <leader>du adds a left column of variables, watches
-- and breakpoints; it leaves the console and the stack alone, so there is
-- only ever one of each.
return {
  "rcarriga/nvim-dap-ui",
  keys = {
    { "<leader>du", function() require("dapui").toggle({}) end, desc = "Variables / watches / breakpoints panels" },
    { "<leader>de", function() require("dapui").eval() end, desc = "Evaluate", mode = { "n", "x" } },
  },
  -- LazyVim's config also opens the panels on every session start; this one
  -- only sets them up and closes them when the session ends
  config = function(_, opts)
    local dap, dapui = require("dap"), require("dapui")
    dapui.setup(opts)
    require("config.dap_panels").setup()
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close({})
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close({})
    end
  end,
  opts = {
    -- the play/step buttons on the console's bar: keys do that (,c <M-o> ...),
    -- and the bar shows the panel's title instead (config/dap_panels.lua)
    controls = { enabled = false },
    layouts = {
      {
        position = "left",
        size = 50,
        elements = {
          { id = "scopes", size = 0.7 },
          { id = "watches", size = 0.15 },
          { id = "breakpoints", size = 0.15 },
        },
      },
    },
  },
}
