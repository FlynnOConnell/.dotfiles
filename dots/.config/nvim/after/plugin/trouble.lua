vim.keymap.set("n", ",q", "<cmd>TroubleToggle quickfix<cr>",
  {silent = true, noremap = true}
)
vim.keymap.set("n", ",t", "<cmd>TroubleToggle<cr>",
  {silent = true, noremap = true}
)
vim.keymap.set("n", ",w", "<cmd>TroubleToggle workspace_diagnostics<cr>",
  {silent = true, noremap = true}
)
vim.keymap.set("n", ",d", "<cmd>TroubleToggle document_diagnostics<cr>",
  {silent = true, noremap = true}
)
vim.keymap.set("n", ",l", "<cmd>TroubleToggle loclist<cr>",
  {silent = true, noremap = true}
 )
vim.keymap.set("n", ",r", "<cmd>TroubleToggle lsp_references<cr>",
  {silent = true, noremap = true}
)

vim.keymap.set("n", "<leader>k", function() require("trouble").next({skip_groups = true, jump = true}) end)
vim.keymap.set("n", "<leader>j", function() require("trouble").previous({skip_groups = true, jump = true}) end)

local wk = require("which-key")
wk.setup {}
wk.register({
    [","] = {
            name = "+trouble",
            q = "quickfix",
            t = "toggle",
            w = "ws-diagnostics",
            d = "doc-diagnostics",
            r = "lsp-refs",
    },
    ["<leader>"] = {
            k = "trouble-next",
            j = "trouble-prev",
    }
})
