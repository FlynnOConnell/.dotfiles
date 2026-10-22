-- noice titles `:!cmd` as "filter"; it just runs a shell command, so say that
return {
  "folke/noice.nvim",
  opts = {
    cmdline = {
      format = {
        filter = { title = " Shell " },
      },
    },
  },
}
