local mark = require("harpoon.mark")
local ui = require("harpoon.ui")
local wk = require("which-key")

vim.keymap.set("n", "<leader>a", mark.add_file)
vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)

vim.keymap.set("n", "<leader>1", function() ui.nav_file(1) end)
vim.keymap.set("n", "<leader>2", function() ui.nav_file(2) end)
vim.keymap.set("n", "<leader>3", function() ui.nav_file(3) end)
vim.keymap.set("n", "<leader>4", function() ui.nav_file(4) end)

wk.register({
    ["<leader>"] = {
        ["a"] = { "add file to mark" },
        ["e"] = { "list all marked files" },
        ["1"] = { nav_file_1, "Mark 1" },
        ["2"] = { nav_file_2, "Mark 2" },
        ["3"] = { nav_file_3, "Mark 3" },
        ["4"] = { nav_file_4, "Mark 4" },
    },
})
