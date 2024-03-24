-- luacheck: globals vim
-- Disable 'q' for recording macro
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- cancel visual selection
vim.keymap.set("v", "<C-f>", "<ESC>")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Keep visual selection
vim.keymap.set("v", "<", "< gv")
vim.keymap.set("v", ">", "> gv")

vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set("n", "ciw", [["_ciw]])
vim.keymap.set("n", "ciw", "\"_ciw", { noremap = true, silent = true })

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])
vim.keymap.set("i", "kj", "<Esc>")

-- remap q and Q
vim.keymap.set("n", "q", "<Nop>", { noremap = true, silent = true })
vim.keymap.set("n", "Q", "<Nop>", { noremap = true, silent = true })
vim.keymap.set("n", "qq", ":qa<CR>", { noremap = true, silent = true })
vim.keymap.set("n", "qa", ":qa<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>r", vim.lsp.buf.format)

vim.keymap.set('n', '<C-J>', '<C-W><C-J>', { noremap = true })
vim.keymap.set('n', '<C-K>', '<C-W><C-K>', { noremap = true })
vim.keymap.set('n', '<C-L>', '<C-W><C-L>', { noremap = true })
vim.keymap.set('n', '<C-H>', '<C-W><C-H>', { noremap = true })

vim.keymap.set('n', '<Left>', '<C-W><', { noremap = true })
vim.keymap.set('n', '<Right>', '<C-W>>', { noremap = true })
vim.keymap.set('n', '<Up>', ':resize -2<CR>', { noremap = true })
vim.keymap.set('n', '<Down>', ':resize +2<CR>', { noremap = true })
vim.keymap.set('n', '<C-=>', '<C-W>=', { noremap = true })

vim.keymap.set('n', '<leader>|', ':vsplit<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<leader>_', ':split<CR>', { noremap = true, silent = true })

vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])
vim.keymap.set("n", "<C-f>", "<cmd>silent !tmux neww tmux-sessionizer<CR>")

-- QUICK ROUTING TO DIRS -------
vim.keymap.set("n", "<leader>Gon", "<cmd>e ~/.config/nvim/<CR>"); -- go nvim
vim.keymap.set("n", "<leader>Gor", "<cmd>e ~/repos/<CR>");        -- go repos
vim.keymap.set("n", "<leader>Got", "<cmd>e ~/config/tmux/<CR>");  -- go tmux config

local wk = require("which-key")

wk.register({
    ["<leader>"] = {
        s = { "replace-all" },
        F = { "Lsp-Format" },
        G = {
            name = "+GoTo",
            o = {
                name = "+open",
                n = { "Go to Neovim Config" },
                r = { "Go to Repos" },
                t = { "Go to Tmux Config" },
                N = {
                    name = "+nvim-dirs",
                    Nw = { "Go to keymaps" },
                    Nl = { "Go to lua dir" },
                    Np = { "Go to plugin dir" },
                },
                R = {
                    name = "+repo-dirs",
                    Rf = { "Go to Repos: Fluke" },
                    Rd = { "Go to Repos: .dotfiles" },
                },
            },
        },
        f = {
            name = "+findFiles",
            f = { "Find Files" },
            g = { "Grep String" },
            b = { "Find Buffers" },
            h = { "Find Help Tags" },
        },
        u = { "Undo-Tree" },
    },
})
