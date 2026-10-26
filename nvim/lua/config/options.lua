-- Options are automatically loaded before lazy.nvim startup.
require("config.remote_clipboard").setup()

vim.opt.relativenumber = false
vim.g.autoformat = false

-- `,` is the local leader: running the debugger and the REPL live on it
-- (,c ,b ,q ..., ,r... ,d...; python-envs.lua, repl.lua), while stepping is
-- on Alt and the debugger's popups and panels on <leader>d. As the local
-- leader, flash.nvim leaves it alone (it would take `,` for reverse f/t), so
-- which-key shows what follows `,`.
vim.g.maplocalleader = ","
