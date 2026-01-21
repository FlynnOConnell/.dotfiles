-- Obsidian.nvim configuration
-- Vault: ~/repos/docs
local vault_path = vim.fn.expand '~/repos/docs'

-- Calculate week range (Monday - Friday)
local function get_week_range()
  local now = os.time()
  local dow = tonumber(os.date('%w', now)) -- 0=Sun, 1=Mon, ..., 6=Sat
  if dow == 0 then dow = 7 end -- Convert Sunday to 7
  local mon = now - (dow - 1) * 86400
  local fri = mon + 4 * 86400
  local mon_month = os.date('%B', mon)
  local fri_month = os.date('%B', fri)
  local mon_day = os.date('%d', mon):gsub('^0', '')
  local fri_day = os.date('%d', fri):gsub('^0', '')
  local year = os.date('%Y', fri)
  if mon_month == fri_month then
    return string.format('%s %s-%s, %s', mon_month, mon_day, fri_day, year)
  else
    return string.format('%s %s – %s %s, %s', mon_month, mon_day, fri_month, fri_day, year)
  end
end

-- Open weekly note (creates from template if doesn't exist)
local function open_weekly()
  local weekly_dir = vault_path .. '/weekly'
  local week_file = os.date '%Y-W%V' .. '.md'
  local full_path = weekly_dir .. '/' .. week_file

  vim.fn.mkdir(weekly_dir, 'p')

  if vim.fn.filereadable(full_path) ~= 1 then
    local template_path = vault_path .. '/templates/weekly.md'
    local template = vim.fn.readfile(template_path)
    local date_short = os.date '%Y-%m-%d'
    local week_range = get_week_range()

    for i, line in ipairs(template) do
      template[i] = line:gsub('{{date}}', date_short):gsub('{{week_range}}', week_range)
    end

    vim.fn.writefile(template, full_path)
  end

  vim.cmd('edit ' .. full_path)
end

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
        name = 'docs',
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

    -- Daily notes: ~/repos/docs/daily/
    daily_notes = {
      folder = 'daily',
      date_format = '%Y-%m-%d',
      template = 'daily.md',  -- Use template from templates folder
    },

    -- Templates: ~/repos/docs/templates/
    templates = {
      folder = 'templates',
      date_format = '%Y-%m-%d',
      time_format = '%H:%M',
    },

    completion = {
      nvim_cmp = true,
      min_chars = 2,
    },

    picker = {
      name = 'telescope.nvim',
      note_mappings = { new = '<C-n>', insert_link = '<C-l>' },
      tag_mappings = { tag_note = '<C-t>', insert_tag = '<C-l>' },
    },

    preferred_link_style = 'wiki',
    open_notes_in = 'current',
    ui = { enable = false },
  },
  keys = {
    { '<leader>oo', '<cmd>Obsidian quick_switch<cr>', desc = '[O]bsidian: [O]pen note' },
    { '<leader>of', '<cmd>Obsidian search<cr>', desc = '[O]bsidian: [F]ind in notes' },
    { '<leader>ob', '<cmd>Obsidian backlinks<cr>', desc = '[O]bsidian: [B]acklinks' },
    { '<leader>ol', '<cmd>Obsidian links<cr>', desc = '[O]bsidian: [L]inks in note' },
    { '<leader>ot', '<cmd>Obsidian tags<cr>', desc = '[O]bsidian: [T]ags' },

    { '<leader>on', '<cmd>Obsidian new<cr>', desc = '[O]bsidian: [N]ew note' },
    { '<leader>od', '<cmd>Obsidian today<cr>', desc = '[O]bsidian: [D]aily note' },
    { '<leader>ow', open_weekly, desc = '[O]bsidian: [W]eekly note' },
    { '<leader>oy', '<cmd>Obsidian yesterday<cr>', desc = '[O]bsidian: [Y]esterday' },
    { '<leader>om', '<cmd>Obsidian tomorrow<cr>', desc = '[O]bsidian: To[M]orrow' },

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
