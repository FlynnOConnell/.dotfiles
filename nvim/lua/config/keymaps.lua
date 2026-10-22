-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Leave insert mode with kj
vim.keymap.set("i", "kj", "<Esc>", { desc = "Exit insert mode" })

-- Curated cheatsheet popup (edit ~/.config/nvim/cheatsheet.md)
vim.keymap.set("n", "<leader>k", function()
  require("config.cheatsheet").toggle()
end, { desc = "Cheatsheet" })

-- Ask a herdr agent (any workspace, or a new Claude split) about the selection
vim.keymap.set("x", "<leader>aa", function()
  require("config.herdr_ask").ask()
end, { desc = "Ask herdr agent about selection" })


-- names for the `,` (local leader) groups in which-key
pcall(function()
  require("which-key").add({ { ",", group = "debug" }, { ",r", group = "repl" }, { ",d", group = "debug run" } })
end)
