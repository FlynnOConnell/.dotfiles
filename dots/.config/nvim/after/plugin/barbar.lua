local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Close Buffers / All Buffers
map('n', '<C-W>', '<Cmd>BufferCloseAllButCurrent<CR>', opts)
map('n', '<C-Q>', '<Cmd>BufferCloseAllButCurrent<CR>', opts)
map('n', '<C-w>', '<Cmd>BufferClose<CR>', opts)
map('n', '<C-q>', '<Cmd>BufferClose<CR>', opts)

-- Navigate Tabs
map('n', '<C-PageUp>', '<Cmd>BufferPrevious<CR>', opts)
map('n', '<C-PageDown>', '<Cmd>BufferNext<CR>', opts)

-- !!! NOTE: This only works if keymaps set correctly in kitty (Below)
map("n", "<C-t>1", "<Cmd>BufferGoto 1<CR>", { noremap = true, silent = true })
map("n", "<C-t>2", "<Cmd>BufferGoto 2<CR>", { noremap = true, silent = true })
map("n", "<C-t>3", "<Cmd>BufferGoto 3<CR>", { noremap = true, silent = true })
map("n", "<C-t>4", "<Cmd>BufferGoto 4<CR>", { noremap = true, silent = true })
map("n", "<C-t>5", "<Cmd>BufferGoto 5<CR>", { noremap = true, silent = true })
map("n", "<C-t>6", "<Cmd>BufferGoto 6<CR>", { noremap = true, silent = true })
map("n", "<C-t>7", "<Cmd>BufferGoto 7<CR>", { noremap = true, silent = true })
map("n", "<C-t>8", "<Cmd>BufferGoto 8<CR>", { noremap = true, silent = true })
map("n", "<C-t>9", "<Cmd>BufferGoto 9<CR>", { noremap = true, silent = true })
map("n", "<C-t>0", "<Cmd>BufferLast<CR>", { noremap = true, silent = true })

