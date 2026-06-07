-- debug.lua
--
-- python debugging via debugpy with automatic venv injection.
-- if a .venv exists in the project, debugpy gets installed into it
-- on first debug launch via `uv pip install debugpy`.

return {
  'mfussenegger/nvim-dap',
  dependencies = {
    'rcarriga/nvim-dap-ui',
    'nvim-neotest/nvim-nio',
    'mfussenegger/nvim-dap-python',
  },
  config = function()
    local dap = require 'dap'
    local dapui = require 'dapui'

    -- find venv python, install debugpy if missing
    local function ensure_debugpy()
      local venv = vim.fn.getcwd() .. '/.venv'
      local is_win = vim.fn.has 'win32' == 1
      local python = is_win and venv .. '/Scripts/python.exe' or venv .. '/bin/python'

      if vim.fn.executable(python) ~= 1 then
        vim.notify('no .venv found in project root, run `uv venv` first', vim.log.levels.WARN)
        return nil
      end

      -- check if debugpy is importable
      local check = vim.fn.system { python, '-c', 'import debugpy' }
      if vim.v.shell_error ~= 0 then
        vim.notify('installing debugpy into .venv...', vim.log.levels.INFO)
        local result = vim.fn.system { 'uv', 'pip', 'install', 'debugpy', '--python', python }
        if vim.v.shell_error ~= 0 then
          vim.notify('failed to install debugpy: ' .. result, vim.log.levels.ERROR)
          return nil
        end
        vim.notify('debugpy installed', vim.log.levels.INFO)
      end

      return python
    end

    -- set up dap-python with venv detection
    local python = ensure_debugpy()
    if python then
      require('dap-python').setup(python)
    end

    -- re-detect venv when changing directories
    vim.api.nvim_create_autocmd('DirChanged', {
      callback = function()
        local py = ensure_debugpy()
        if py then
          require('dap-python').setup(py)
        end
      end,
    })

    -- keymaps
    vim.keymap.set('n', ',c', dap.continue, { desc = 'Debug: Start/Continue' })
    vim.keymap.set('n', ',i', dap.step_into, { desc = 'Debug: Step Into' })
    vim.keymap.set('n', ',o', dap.step_over, { desc = 'Debug: Step Over' })
    vim.keymap.set('n', ',O', dap.step_out, { desc = 'Debug: Step Out' })
    vim.keymap.set('n', ',b', dap.toggle_breakpoint, { desc = 'Debug: Toggle Breakpoint' })
    vim.keymap.set('n', ',B', function()
      dap.set_breakpoint(vim.fn.input 'Breakpoint condition: ')
    end, { desc = 'Debug: Set Breakpoint' })

    dapui.setup {
      icons = { expanded = '▾', collapsed = '▸', current_frame = '*' },
      controls = {
        icons = {
          pause = '⏸',
          play = '▶',
          step_into = '⏎',
          step_over = '⏭',
          step_out = '⏮',
          step_back = 'b',
          run_last = '▶▶',
          terminate = '⏹',
          disconnect = '⏏',
        },
      },
    }

    vim.keymap.set('n', ',r', dapui.toggle, { desc = 'Debug: See last session result.' })

    dap.listeners.after.event_initialized['dapui_config'] = dapui.open
    dap.listeners.before.event_terminated['dapui_config'] = dapui.close
    dap.listeners.before.event_exited['dapui_config'] = dapui.close
  end,
}
