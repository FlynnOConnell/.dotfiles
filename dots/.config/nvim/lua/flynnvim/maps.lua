local wk = require("which-key")

wk.setup {
    -- optional configs, empty is default
}

-- method 2
wk.register({
    ["<C-p>"] = {"Find git files"},
    ["<leader>"] = {
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
                R= {
                    name = "+repo-dirs",
                    Rf = { "Go to Repos: Fluke" },
                    Rd = { "Go to Repos: .dotfiles" },
                },
            },
        },
        p = {
            name = "+findFiles",
            v = {"Ex"},
            f = {"Find Files"},
            g = {"Grep String"},
            b = {"Find Buffers"},
            h = {"Find Help Tags"},
        },
        u = {"Undo-Tree"},
    },
})

