local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fs', function()
    builtin.grep_string({ search = vim.fn.input("Grep > ") })
end)
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

local wk = require("which-key")

wk.register({
    ["<leader>"] = {
        s = { "replace-all" },
        F = { "Lsp-Format" },
        f = {
            name = "+find",
            f = { "Find Files" },
            s = { "Grep String" },
            b = { "Find Buffers" },
            h = { "Find Help Tags" },
        },
    },
})
