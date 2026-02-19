return {
  'greggh/claude-code.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  keys = {
    { '<leader>cc', '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude Code' },
    { '<leader>cC', '<cmd>ClaudeCodeContinue<cr>', desc = 'Claude Code Continue' },
    { '<leader>cR', '<cmd>ClaudeCodeResume<cr>', desc = 'Claude Code Resume' },
  },
  cmd = {
    'ClaudeCode',
    'ClaudeCodeContinue',
    'ClaudeCodeResume',
    'ClaudeCodeVerbose',
  },
  config = function()
    require('claude-code').setup {
      window = {
        position = 'float',
        float = {
          width = '90%',
          height = '90%',
          row = 'center',
          col = 'center',
          border = 'rounded',
        },
      },
      keymaps = {
        toggle = {
          normal = '<C-,>',
          terminal = '<C-,>',
        },
      },
    }
  end,
}
