-- sciview: the debugger companion app (~/repos/sciview), whose nvim side is
-- a local plugin: the viewer window (,m ,dv), run configs (,dd ,s) and
-- :SciviewEnv. Loaded on first require; python-envs.lua calls its setup()
-- when nvim-dap loads, and its keys are there too.
return {
  {
    dir = "~/repos/sciview/nvim",
    name = "sciview",
    lazy = true,
  },
}
