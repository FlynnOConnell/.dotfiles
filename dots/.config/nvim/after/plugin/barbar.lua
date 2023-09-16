local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Move to previous/next
map('n', '<C-p>', '<Cmd>BufferPrevious<CR>', opts)
map('n', '<C-n>', '<Cmd>BufferNext<CR>', opts)
-- Goto buffer in position...
map('n', '<Space>b1', '<Cmd>BufferLast<CR>', opts)
map('n', '<Space>b0', '<Cmd>BufferLast<CR>', opts)

map('n', '<Space>bw', '<Cmd>BufferClose<CR>', opts)
map('n', '<Space>bq', '<Cmd>BufferClose<CR>', opts)
map('n', '<Space>bW', '<Cmd>BufferCloseAllButCurrent<CR>', opts)
map('n', '<Space>bQ', '<Cmd>BufferCloseAllButCurrent<CR>', opts)
