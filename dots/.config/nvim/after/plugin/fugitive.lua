vim.keymap.set("n", "<leader>hs", vim.cmd.Git)
vim.keymap.set("n", "<leader>hg", "<cmd>:lazygit<CR>")

local Big_Fug = vim.api.nvim_create_augroup("Big_Fug", {})

local autocmd = vim.api.nvim_create_autocmd
autocmd("BufWinEnter", {
    group = Big_Fug,
    pattern = "*",
    callback = function()
        if vim.bo.ft ~= "fugitive" then
            return
        end

        local bufnr = vim.api.nvim_get_current_buf()
        local opts = {buffer = bufnr, remap = false}
        vim.keymap.set("n", "<leader>hp", function()
            vim.cmd.Git('push')
        end, opts)

        -- rebase always
        vim.keymap.set("n", "<leader>hP", function()
            vim.cmd.Git({'pull',  '--rebase'})
        end, opts)

        -- NOTE: It allows me to easily set the branch i am pushing and any tracking
        -- needed if i did not set the branch up correctly
        vim.keymap.set("n", "<leader>ht", ":Git push -u origin ", opts);
    end,
})

local wk = require("which-key")

wk.register({
    ["<leader>"] = {
        h = {
            name = "+git",
            s = { "Run Git" },
            g = { "Run Lazygit" },
            p = { "Git PUSH" },
            P = { "Git PULL/REBASE" },
        },
    },
})
