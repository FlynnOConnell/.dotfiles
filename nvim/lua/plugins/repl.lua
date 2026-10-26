-- IPython REPL you send code to from the buffer, like PyCharm's
-- "Execute selection in Python console". Starts the active env's ipython
-- (VIRTUAL_ENV, set in python-envs.lua), so it sees the same packages as the
-- debugger and tests. `# %%` lines split a file into cells.
return {
  "Vigemus/iron.nvim",
  ft = "python",
  cmd = { "IronRepl", "IronRestart", "IronFocus", "IronHide" },
  keys = {
    { ",rs", "<cmd>IronRepl<cr>", desc = "REPL toggle" },
    { ",rR", "<cmd>IronRestart<cr>", desc = "REPL restart" },
  },
  config = function()
    local view = require("iron.view")
    local common = require("iron.fts.common")
    require("iron.core").setup({
      config = {
        scratch_repl = true,
        repl_open_cmd = view.split.vertical.botright(0.4),
        repl_definition = {
          python = {
            command = function()
              -- python -m IPython, so frozen modules can be turned off: they
              -- can't take breakpoints and make debugpy warn on attach
              local venv = vim.env.VIRTUAL_ENV
              local python = venv and venv .. "/bin/python" or "python3"
              return { python, "-X", "frozen_modules=off", "-m", "IPython", "--no-autoindent" }
            end,
            format = common.bracketed_paste_python,
            block_dividers = { "# %%", "#%%" },
          },
        },
      },
      keymaps = {
        send_line = ",rl",
        visual_send = ",rr",
        send_until_cursor = ",ru",
        send_file = ",rf",
        interrupt = ",ri",
        clear = ",rx",
        exit = ",rq",
      },
      highlight = { italic = true },
      ignore_blank_lines = true,
    })
    require("which-key").add({
      { ",r", group = "repl" },
      { ",rl", desc = "Run line" },
      { ",rr", desc = "Run selection", mode = "x" },
      { ",ru", desc = "Run file up to cursor" },
      { ",rf", desc = "Run file" },
      { ",ri", desc = "Interrupt" },
      { ",rx", desc = "Clear" },
      { ",rq", desc = "Quit REPL" },
    })

    -- Attach nvim-dap to the REPL's python: debugpy listens inside ipython and
    -- dap connects to it, so breakpoints in real files (masknmf source) stop
    -- when a sent cell calls into them. The REPL keeps running hidden while
    -- the dap-ui panels are up; ,rs shows it again.
    local core = require("iron.core")

    -- each REPL process gets its own free port, so two nvims with REPLs (or
    -- anything else on 5678) don't collide; a restarted REPL gets a new one
    local listening = { job = nil, port = nil }
    local function free_port()
      local tcp = vim.uv.new_tcp()
      tcp:bind("127.0.0.1", 0)
      local port = tcp:getsockname().port
      tcp:close()
      return port
    end

    local function attach(on_ready)
      local dap = require("dap")
      if dap.session() then
        if on_ready then
          on_ready()
        end
        return
      end
      local meta = require("iron.state").get_repl("python")
      local running = require("iron.lowlevel").repl_exists(meta)
      if not (running and listening.job == meta.job) then
        listening.port = free_port()
      end
      local port = listening.port
      core.send("python", {
        string.format(
          "import debugpy; _ = getattr(debugpy, '_nvim_port', None) or setattr(debugpy, '_nvim_port', debugpy.listen(('127.0.0.1', %d)))",
          port
        ),
      })
      listening.job = require("iron.state").get_repl("python").job
      -- debugpy.breakpoint() is a no-op until a client is connected, so wait
      -- for the attach handshake to finish before sending anything to pause on
      dap.listeners.after.configurationDone["repl_attach"] = function()
        dap.listeners.after.configurationDone["repl_attach"] = nil
        vim.schedule(function()
          core.hide_repl("python")
          if on_ready then
            on_ready()
          end
        end)
      end
      vim.defer_fn(function()
        dap.run({
          type = "python",
          request = "attach",
          name = "attach to REPL",
          connect = { host = "127.0.0.1", port = port },
          justMyCode = true,
          -- nvim_repl.run_cell is plumbing: keep it out of the stack
          rules = { { path = vim.fn.stdpath("config") .. "/python/nvim_repl.py", include = false } },
        })
      end, running and 1500 or 6000)
    end

    local function has_cells(buf)
      for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        if line:match("^#%s*%%%%") then
          return true
        end
      end
      return false
    end

    -- the `# %%` cell around `row` in `buf`: its first and last line numbers
    -- and its lines (the whole file when there are no dividers)
    local function cell_at(buf, row)
      local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
      local first, last = 1, #lines
      for i = row, 1, -1 do
        if lines[i]:match("^#%s*%%%%") then
          first = i + 1
          break
        end
      end
      for i = row + 1, #lines do
        if lines[i]:match("^#%s*%%%%") then
          last = i - 1
          break
        end
      end
      return first, last, vim.list_slice(lines, first, last)
    end

    -- a breakpoint ,C added just to stop at the cursor; removed on the
    -- next stop, or before the next cell runs if the cell never reached it
    local temp_bp = nil
    local function clear_temp_bp()
      if not temp_bp then
        return
      end
      local bp, dap = temp_bp, require("dap")
      temp_bp = nil
      if vim.api.nvim_buf_is_valid(bp.buf) then
        require("dap.breakpoints").remove(bp.buf, bp.line)
        for _, session in pairs(dap.sessions()) do
          session:set_breakpoints(require("dap.breakpoints").get(bp.buf))
        end
      end
    end

    -- runs a cell through python/nvim_repl.py, as code from its file at its
    -- real line numbers: tracebacks, breakpoints and the debugger's stack
    -- show the file itself, not `<ipython-input-N>`
    local helper_dir = vim.fn.stdpath("config") .. "/python"
    local last_cell = nil -- { buf, row } of the last cell sent, for ,C
    local function send_cell(pause, buf, row)
      buf = buf or vim.api.nvim_get_current_buf()
      row = row or vim.api.nvim_win_get_cursor(0)[1]
      last_cell = { buf = buf, row = row }
      -- the debugger reads the file from disk, so line numbers must match it
      vim.api.nvim_buf_call(buf, function()
        vim.cmd("silent update")
      end)
      local first, last, cell = cell_at(buf, row)
      local code = string.format(
        "__import__('sys').path.insert(0, %q) if %q not in __import__('sys').path else None; __import__('nvim_repl').run_cell('%s', %q, %d, %s)",
        helper_dir,
        helper_dir,
        vim.base64.encode(table.concat(cell, "\n") .. "\n"),
        vim.api.nvim_buf_get_name(buf),
        first,
        pause and "True" or "False"
      )
      core.send("python", code)
      return last
    end

    -- PyCharm's "Run cell": run it, then move to the next cell
    vim.keymap.set("n", ",rc", function()
      clear_temp_bp()
      local last = send_cell(false)
      local next_line = math.min(last + 2, vim.api.nvim_buf_line_count(0))
      vim.api.nvim_win_set_cursor(0, { next_line, 0 })
    end, { desc = "REPL run cell, next" })

    -- Stepping off the end of a cell stops in its caller: the one-line REPL
    -- input that started it (`nvim_repl.run_cell(...)`, `<ipython-input-N>`).
    -- Nothing to see there, so don't open it; let the cell finish instead.
    local dap = require("dap")
    local stopped_by_step = false
    dap.listeners.before.event_stopped["repl_cell_end"] = function(_, body)
      stopped_by_step = body.reason == "step"
    end
    dap.listeners.before.stackTrace["repl_cell_end"] = function(session, err, response)
      if not stopped_by_step or err or not response then
        return
      end
      stopped_by_step = false
      local top = response.stackFrames and response.stackFrames[1]
      local source = top and top.source
      if source and (source.path or source.name or ""):match("^<ipython%-input") then
        top.line = -1 -- nvim-dap doesn't jump to a frame with a negative line
        vim.schedule(function()
          if session.stopped_thread_id then
            dap.continue()
          end
        end)
      end
    end

    vim.keymap.set("n", ",da", function()
      attach()
    end, { desc = "REPL attach debugger" })

    -- PyCharm's "Debug cell": run the cell paused on its first line, then
    -- <M-i> steps into whatever it calls, opening each file as it goes
    vim.keymap.set("n", ",dr", function()
      clear_temp_bp()
      -- take the cell now: attaching opens the dap-ui panels and moves focus
      local buf, row = vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)[1]
      attach(function()
        send_cell(true, buf, row)
      end)
    end, { desc = "REPL debug cell" })

    -- Run to cursor from anywhere (,C, python-envs.lua): when paused
    -- it's plain run_to_cursor; otherwise the cursor line gets a temporary
    -- breakpoint and a cell runs, the one under the cursor in a `# %%` file,
    -- else the last cell sent (cursor in masknmf source: "run my cell until
    -- it gets here"). Other breakpoints on the way still stop it.
    package.loaded["repl_run_to_cursor"] = function()
      local dap = require("dap")
      local session = dap.session()
      if session and session.stopped_thread_id then
        return dap.run_to_cursor()
      end
      local buf, row = vim.api.nvim_get_current_buf(), vim.api.nvim_win_get_cursor(0)[1]
      local target = has_cells(buf) and { buf = buf, row = row } or last_cell
      if not target or not vim.api.nvim_buf_is_valid(target.buf) then
        vim.notify("run a cell first: ,C here reruns the last cell until it reaches this line", vim.log.levels.WARN)
        return
      end
      clear_temp_bp()
      local existing = require("dap.breakpoints").get(buf)[buf] or {}
      if not vim.iter(existing):any(function(bp)
        return bp.line == row
      end) then
        dap.set_breakpoint()
        temp_bp = { buf = buf, line = row }
      end
      dap.listeners.after.event_stopped["repl_run_to_cursor"] = function()
        dap.listeners.after.event_stopped["repl_run_to_cursor"] = nil
        vim.schedule(clear_temp_bp)
      end
      attach(function()
        send_cell(false, target.buf, target.row)
      end)
    end
  end,
}
