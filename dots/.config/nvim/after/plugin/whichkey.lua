local wk = require("which-key")
wk.setup {}
wk.register({
    ["<leader>"] = {
        c = {
            name = "+crates",
            r = "reload",
            f = "features-popup",
            u = "upgrade/update",
            a = "upgrate/update all",
        }
    }
})
