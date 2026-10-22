-- Obsidian.nvim configuration
-- Vault: ~/repos/arctic-lake
local vault_path = vim.fn.expand '~/repos/arctic-lake'

return {
  'obsidian-nvim/obsidian.nvim',
  version = '*',
  lazy = true,
  event = { 'BufReadPre ' .. vault_path .. '/**.md' },
  cmd = { 'Obsidian' },
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope.nvim',
    'hrsh7th/nvim-cmp',
  },
  opts = {
    legacy_commands = false,
    workspaces = {
      {
        name = 'arctic-lake',
        path = vault_path,
      },
    },

    frontmatter = { enabled = false },

    note_id_func = function(title)
      if title ~= nil then
        return title:gsub(' ', '-'):gsub('[^A-Za-z0-9-]', ''):lower()
      else
        return tostring(os.time())
      end
    end,

    -- Templates: ~/repos/arctic-lake/templates/
    templates = {
      folder = 'templates',
      date_format = '%Y-%m-%d',
      time_format = '%H:%M',
    },

    completion = {
      -- nvim_cmp removed: completion is now served by the built-in obsidian-ls LSP
      min_chars = 2,
    },

    picker = {
      name = 'telescope.nvim',
      note_mappings = { new = '<C-n>', insert_link = '<C-l>' },
      tag_mappings = { tag_note = '<C-t>', insert_tag = '<C-l>' },
    },

    link = { style = 'wiki' },
    open_notes_in = 'current',
    ui = { enable = false },
    statusline = { enabled = false },
  },
  keys = {
    { '<leader>oo', '<cmd>Obsidian quick_switch<cr>', desc = '[O]bsidian: [O]pen note' },
    { '<leader>of', '<cmd>Obsidian search<cr>', desc = '[O]bsidian: [F]ind in notes' },
    { '<leader>ob', '<cmd>Obsidian backlinks<cr>', desc = '[O]bsidian: [B]acklinks' },
    { '<leader>ol', '<cmd>Obsidian links<cr>', desc = '[O]bsidian: [L]inks in note' },
    { '<leader>ot', '<cmd>Obsidian tags<cr>', desc = '[O]bsidian: [T]ags' },

    { '<leader>on', '<cmd>Obsidian new<cr>', desc = '[O]bsidian: [N]ew note' },

    { '<leader>oc', '<cmd>Obsidian toc<cr>', desc = '[O]bsidian: Table of [C]ontents' },
    { '<leader>or', '<cmd>Obsidian rename<cr>', desc = '[O]bsidian: [R]ename note' },
    { '<leader>oi', '<cmd>Obsidian paste_img<cr>', desc = '[O]bsidian: Paste [I]mage' },
    { '<leader>op', '<cmd>Obsidian template<cr>', desc = '[O]bsidian: Insert tem[P]late' },

    { 'gf', '<cmd>Obsidian follow_link<cr>', desc = '[O]bsidian: Follow link', ft = 'markdown' },
    { '<leader>ox', '<cmd>Obsidian toggle_checkbox<cr>', desc = '[O]bsidian: Toggle checkbo[X]' },

    { '<leader>ol', '<cmd>Obsidian link<cr>', desc = '[O]bsidian: Create [L]ink', mode = 'v' },
    { '<leader>oe', '<cmd>Obsidian extract_note<cr>', desc = '[O]bsidian: [E]xtract to note', mode = 'v' },

    { '<leader>oO', '<cmd>Obsidian open<cr>', desc = '[O]bsidian: Open in app' },
  },
}
