-- Find uv envs kept in ~/envs/<name>/.venv for <leader>cv (VenvSelect).
-- The last pick is cached per project directory.
-- Until something is picked, pyright and debugpy use the project's own .venv
-- (uv project), else FALLBACK_ENV.
local FALLBACK_ENV = vim.fn.expand("~/envs/pml/.venv")
local FROZEN_OFF = { "-X", "frozen_modules=off" }
-- debug runs of pytest load python/nvim_pytest_debug.py, which stops the
-- debugger on a failing test's raising line
local HELPERS = vim.fn.stdpath("config") .. "/python"
local PYTEST_DEBUG_ENV = {
  PYTEST_PLUGINS = "nvim_pytest_debug",
  PYTHONPATH = vim.env.PYTHONPATH and (HELPERS .. ":" .. vim.env.PYTHONPATH) or HELPERS,
}
local DEFAULT_ENV = vim.fs.root(vim.fn.getcwd(), ".venv")
DEFAULT_ENV = DEFAULT_ENV and DEFAULT_ENV .. "/.venv" or FALLBACK_ENV
if vim.env.VIRTUAL_ENV == nil and vim.uv.fs_stat(DEFAULT_ENV) then
  vim.env.VIRTUAL_ENV = DEFAULT_ENV
  vim.env.PATH = DEFAULT_ENV .. "/bin:" .. vim.env.PATH
end

return {
  {
    "linux-cultist/venv-selector.nvim",
    opts = {
      search = {
        envs = {
          command = "fd '/\\.venv/bin/python$' $HOME/envs --full-path --color never -HI -a",
        },
      },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.pyright = vim.tbl_deep_extend("force", opts.servers.pyright or {}, {
        settings = { python = { pythonPath = (vim.env.VIRTUAL_ENV or DEFAULT_ENV) .. "/bin/python" } },
      })
    end,
  },
  {
    -- Run debugpy on the same Python version as the program's env so its
    -- compiled tracer loads (mason's debugpy is built for another version and
    -- falls back to the slow pure-Python one). The env is the launch config's
    -- `python` (a run config's project env, sciview), else the active one.
    -- Uses the env's own debugpy if installed, else a cached uv tool env.
    "mfussenegger/nvim-dap-python",
    config = function()
      local dap = require("dap")
      require("dap-python").setup("debugpy-adapter")
      local adapter_for = dap.adapters.python
      dap.adapters.python = function(cb, config)
        adapter_for(function(adapter)
          local program_python = type(config.python) == "table" and config.python[1] or config.python
          local venv = program_python and vim.fs.dirname(vim.fs.dirname(program_python)) or vim.env.VIRTUAL_ENV
          if adapter.type == "executable" and venv then
            local python = program_python or venv .. "/bin/python"
            if vim.fn.glob(venv .. "/lib/python*/site-packages/debugpy") ~= "" then
              adapter.command, adapter.args = python, { "-m", "debugpy.adapter" }
            else
              adapter.command = "uv"
              adapter.args = { "tool", "run", "--python", python, "--from", "debugpy", "debugpy-adapter" }
            end
          end
          cb(adapter)
        end, config)
      end
      dap.adapters.debugpy = dap.adapters.python

      -- ,c offers this beside "file": debug any pytest selection,
      -- e.g. `tests/test_io.py -k drop_group` or `tests/test_io.py::test_x`
      table.insert(dap.configurations.python, {
        type = "python",
        request = "launch",
        name = "pytest: choose tests",
        module = "pytest",
        args = function()
          local input = vim.fn.input("pytest args: ", vim.fn.expand("%:.") .. " -x -k ")
          return vim.split(input, " ", { trimempty = true })
        end,
        justMyCode = true,
        env = PYTEST_DEBUG_ENV,
      })

      -- frozen stdlib modules can't take breakpoints and make debugpy print a
      -- warning; every python the debugger launches runs without them
      -- the program runs in a terminal (colors, progress bars, input), shown
      -- on <leader>dt (config/dap_layout.lua)
      for _, c in ipairs(dap.configurations.python) do
        if c.request == "launch" then
          c.pythonArgs = FROZEN_OFF
          c.console = "integratedTerminal"
        end
      end

      -- Stop only on errors that actually end the run, never on ones a
      -- library (torch, pytest.raises, ...) raises and handles itself:
      -- "uncaught" covers plain scripts; the IPython REPL and pytest catch
      -- everything, so python/nvim_repl.py and python/nvim_pytest_debug.py
      -- hand a cell's or test's fatal error to the debugger themselves. The
      -- stop is on the innermost line of your code, with the whole stack
      -- (<C-p>/<C-n>, <leader>ds).
      dap.defaults.python.exception_breakpoints = { "uncaught" }

      -- debugpy's matplotlib support switches an interactive backend (qtagg)
      -- on and runs its GUI loop inside the debugger, which crashes Qt
      -- programs; every python debug run (launch, tests, REPL attach) goes
      -- without it
      dap.listeners.on_config["no_gui_event_loop"] = function(config)
        if config.type == "python" or config.type == "debugpy" then
          config = vim.deepcopy(config)
          config.guiEventLoop = config.guiEventLoop or "none"
        end
        return config
      end

      -- a pause asks the editor not to move (preserveFocusHint): show where
      -- it stopped anyway, at the innermost frame of your code
      dap.listeners.after.event_stopped["pause_focus"] = function(_, body)
        if body.reason == "pause" then
          vim.defer_fn(function()
            if dap.session() then
              dap.focus_frame()
            end
          end, 300)
        end
      end

      -- nothing opens when debugging starts: <leader>dc shows the debug
      -- console (`dap >` prompt) and the call stack, <leader>dt the program's
      -- terminal.
      -- Frames always show in a code window, never in those.
      require("config.dap_layout").setup()

      -- sciview (~/repos/sciview): its viewer follows every run
      require("sciview").setup()

      -- say what the exception was, not just where
      dap.listeners.after.event_stopped["exception_message"] = function(session, body)
        if body.reason ~= "exception" then
          return
        end
        session:request("exceptionInfo", { threadId = body.threadId }, function(err, info)
          if not err and info then
            -- debugpy appends "(note: full exception trace is shown ...)" to the name
            local name = (info.exceptionId or "Exception"):gsub("%s*%(note:.*$", "")
            vim.notify(name .. ": " .. (info.description or ""), vim.log.levels.ERROR, { title = "Exception" })
          end
        end)
      end

      -- While paused, hide inline diagnostics so the end of each line shows
      -- the debugger's variable values instead. Every step resumes and stops
      -- again within milliseconds, so wait a moment before bringing them back.
      local saved_virtual_text, restore_timer = nil, nil
      local function cancel_restore()
        if restore_timer and not restore_timer:is_closing() then
          restore_timer:stop()
          restore_timer:close()
        end
        restore_timer = nil
      end
      local function restore_diagnostics()
        cancel_restore()
        if saved_virtual_text ~= nil then
          vim.diagnostic.config({ virtual_text = saved_virtual_text })
          saved_virtual_text = nil
        end
      end
      dap.listeners.after.event_stopped["hide_diagnostics"] = function()
        cancel_restore()
        if saved_virtual_text == nil then
          saved_virtual_text = vim.diagnostic.config().virtual_text
          vim.diagnostic.config({ virtual_text = false })
        end
      end
      dap.listeners.after.event_continued["hide_diagnostics"] = function()
        cancel_restore()
        restore_timer = vim.defer_fn(function()
          restore_timer = nil
          local session = dap.session()
          if not (session and session.stopped_thread_id) then
            restore_diagnostics()
          end
        end, 500)
      end
      for _, event in ipairs({ "event_terminated", "event_exited", "disconnect" }) do
        dap.listeners.after[event]["hide_diagnostics"] = function()
          vim.schedule(restore_diagnostics)
        end
      end
    end,
  },
  {
    "mfussenegger/nvim-dap",
    keys = function(_, keys)
      -- LazyVim's <leader>d debug keys are gone: running the debugger is on
      -- `,` (the local leader), and <leader>d has the keys below that open
      -- things (profiler keys <leader>dp* stay)
      keys = vim.tbl_filter(function(k)
        return not (type(k[1]) == "string" and k[1]:match("^<leader>d") and not k[1]:match("^<leader>dp"))
      end, keys)
      local dap = function()
        return require("dap")
      end
      -- the session, if it's paused. Held keys repeat faster than a step
      -- finishes: presses that land mid-step, or past either end of the
      -- stack, are dropped instead of each popping a warning
      local function paused()
        local session = dap().session()
        return session and session.stopped_thread_id and session
      end
      local function step(method)
        return function()
          if paused() then
            dap()[method]()
          end
        end
      end
      -- up (+1, toward the caller) or down (-1) the stack
      local function frame(delta)
        return function()
          local session = paused()
          local thread = session and session.current_frame and session.threads[session.stopped_thread_id]
          for i, f in ipairs(thread and thread.frames or {}) do
            if f.id == session.current_frame.id then
              return session:_frame_set(thread.frames[i + delta])
            end
          end
        end
      end
      -- `,` runs the program, Alt steps it (hold and repeat), Ctrl+P/N fly
      -- through the stack, and <leader>d opens things
      return vim.list_extend(keys, {
        { ",c", function() dap().continue() end, desc = "Start / continue" },
        { ",q", function() dap().terminate() end, desc = "Terminate" },
        { "<M-o>", step("step_over"), desc = "Step over" },
        { "<M-i>", step("step_into"), desc = "Step into" },
        { "<M-u>", step("step_out"), desc = "Step out" },
        { "<C-p>", frame(1), desc = "Up the stack (toward the caller)" },
        { "<C-n>", frame(-1), desc = "Down the stack" },
        { "<leader>dt", function() require("config.dap_layout").toggle_terminal() end, desc = "Program's terminal (its output)" },
        { ",b", function() dap().toggle_breakpoint() end, desc = "Toggle breakpoint" },
        {
          ",B",
          function()
            dap().set_breakpoint(vim.fn.input("Breakpoint condition: "))
          end,
          desc = "Conditional breakpoint",
        },
        { ",l", function() dap().run_last() end, desc = "Rerun last" },
        { ",p", function() require("config.dap_layout").pause() end, desc = "Pause" },
        { ",g", function() require("config.dap_layout").goto_current() end, desc = "Go to the paused line (the arrow)" },
        { "<leader>dc", function() require("config.dap_layout").toggle() end, desc = "Debug console + call stack" },
        { ",dd", function() require("sciview.run_configs").open() end, desc = "Run configs (saved commands)" },
        { ",dv", function() require("sciview").open_configs() end, desc = "Run configs in the viewer (a form)" },
        {
          ",dc",
          function()
            for _, config in ipairs(dap().configurations.python or {}) do
              if config.name == "file" then
                return dap().run(config)
              end
            end
            dap().continue()
          end,
          desc = "Debug current file",
        },
      {
        -- replaces LazyVim's, which only works while paused (repl.lua)
        ",C",
        function()
          local ok, run = pcall(require, "repl_run_to_cursor")
          if ok then
            run()
          else
            require("dap").run_to_cursor()
          end
        end,
        desc = "Run to Cursor (runs the cell if not paused)",
      },
      {
        -- "run this and stop" at the cursor line, before it runs; other
        -- breakpoints on the way are skipped. Paused: from where it is.
        -- Not debugging: asks which ,dd command to start, the last one first
        "<M-s>",
        function()
          local session = require("dap").session()
          if not session then
            require("sciview.run_configs").run_to_here()
          elseif session.stopped_thread_id then
            require("dap").run_to_cursor()
          else
            vim.notify("still running: ,p pauses it, or set a breakpoint", vim.log.levels.INFO)
          end
        end,
        desc = "Run to here and stop",
      },
      {
        -- type, shape, dtype and min/max/mean/std of the expression under the
        -- cursor (or selected); lazy arrays get no stats (no full load)
        "<leader>dv",
        function()
          local expr
          local mode = vim.fn.mode()
          if mode:match("^[vV\22]") then
            expr = table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode }), "\n")
            vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
          else
            expr = require("sciview").expr_at_cursor()
          end
          require("config.dap_popups").summary(expr)
        end,
        mode = { "n", "x" },
        desc = "Value Summary (shape, dtype, stats)",
      },
      {
        -- open the value under the cursor (or the selected expression) in the
        -- sciview window: movies with a time slider, images, traces
        "<leader>dm",
        function()
          local expr
          local mode = vim.fn.mode()
          if mode:match("^[vV\22]") then
            expr = table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos("."), { type = mode }), " ")
            vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
          else
            expr = require("sciview").expr_at_cursor()
          end
          require("sciview").show(expr)
        end,
        mode = { "n", "x" },
        desc = "Show in Viewer (movies, images, traces)",
      },
      {
        -- expandable tree of every variable on the cursor line (the inline
        -- values), <CR> opens an entry: array shape/dtype/min/max, attributes
        "<leader>dl",
        function()
          require("config.dap_popups").line_values()
        end,
        desc = "Expand Values on Line",
      },
      {
        -- popup of the variables you defined in the current frame (IPython's
        -- In/Out/_i*, modules and _names left out); <CR> summary, o expand
        "<leader>dV",
        function()
          require("config.dap_popups").variables()
        end,
        desc = "Variables (popup)",
      },
      {
        "<leader>ds",
        function()
          local widgets = require("dap.ui.widgets")
          widgets.centered_float(widgets.frames)
          -- dap's float fills the screen with no border: shrink it to its
          -- lines and frame it like the other popups
          local win = vim.api.nvim_get_current_win()
          local buf = vim.api.nvim_win_get_buf(win)
          local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
          local width = 40
          for _, line in ipairs(lines) do
            width = math.max(width, vim.fn.strdisplaywidth(line) + 2)
          end
          width = math.min(width, math.floor(vim.o.columns * 0.8))
          local height = math.min(math.max(#lines, 3), math.floor(vim.o.lines * 0.6))
          vim.api.nvim_win_set_config(win, {
            relative = "editor",
            width = width,
            height = height,
            row = math.floor((vim.o.lines - height) / 2) - 1,
            col = math.floor((vim.o.columns - width) / 2),
            border = "rounded",
            title = " Call stack ",
            title_pos = "center",
            footer = " <CR> jump  q close ",
            footer_pos = "right",
          })
          vim.wo[win].cursorline = true
          for _, key in ipairs({ "q", "<Esc>" }) do
            vim.keymap.set("n", key, "<cmd>close<cr>", { buffer = buf, nowait = true })
          end
        end,
        desc = "Stack Frames (Enter jumps)",
      },
      })
    end,
  },
  {
    -- <leader>td: frozen-modules fix and stop-on-failure for tests run under
    -- the debugger
    "nvim-neotest/neotest",
    optional = true,
    opts = {
      adapters = {
        ["neotest-python"] = {
          dap = { justMyCode = true, pythonArgs = FROZEN_OFF, env = PYTEST_DEBUG_ENV, console = "integratedTerminal" },
        },
      },
    },
  },
}
