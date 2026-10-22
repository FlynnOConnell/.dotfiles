-- The panels no longer open when debugging starts: the code shows values
-- inline, and popups cover the rest (,V variables, ,v one
-- value, ,f frames, ,D the debug REPL). ,u still
-- opens the full panel set laid out below: variables get most of the left
-- column, the bottom is only the debug REPL.
return {
  "rcarriga/nvim-dap-ui",
  keys = {
    { "<leader>du", false },
    { "<leader>de", false },
    {
      ",u",
      function()
        -- the panels include the console: swap the standalone one out while
        -- they're open, and back in when they close
        local dap, dapui = require("dap"), require("dapui")
        local opening = vim.tbl_isempty(vim.tbl_filter(function(win)
          return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "dapui_scopes"
        end, vim.api.nvim_tabpage_list_wins(0)))
        if opening then
          dap.repl.close()
          dapui.open({})
        else
          dapui.close({})
          if dap.session() then
            local win = vim.api.nvim_get_current_win()
            dap.repl.open({ height = 12 }, "botright split")
            vim.api.nvim_set_current_win(win)
          end
        end
      end,
      desc = "All debug panels",
    },
    { ",e", function() require("dapui").eval() end, desc = "Evaluate", mode = { "n", "x" } },
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
    -- the play/step buttons on the console's bar: keys do that (,c ,o ...),
    -- and the bar shows the panel's title instead (config/dap_panels.lua)
    controls = { enabled = false },
    layouts = {
      {
        position = "left",
        size = 50,
        elements = {
          { id = "scopes", size = 0.6 },
          { id = "stacks", size = 0.2 },
          { id = "watches", size = 0.1 },
          { id = "breakpoints", size = 0.1 },
        },
      },
      {
        -- just the debug REPL (`dap >`), full width: the console element is
        -- empty when attached to the IPython REPL, and launched programs
        -- print here instead (console = "internalConsole", python-envs.lua)
        position = "bottom",
        size = 12,
        elements = {
          { id = "repl", size = 1 },
        },
      },
    },
  },
}
