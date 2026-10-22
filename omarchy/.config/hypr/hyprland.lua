-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- GUI dev windows open on workspace 5 without stealing focus.
o.window({ class = "^ophys.*" }, { workspace = "5 silent" })

-- sciview (nvim debugger array viewer): floats on the right of the current
-- workspace without taking focus from the editor, fully opaque so images
-- show true values.
o.window({ title = "^sciview$" }, {
  float = true,
  no_initial_focus = true,
  size = { "(monitor_w*0.55)", "(monitor_h*0.88)" },
  move = { "(monitor_w*0.43)", "(monitor_h*0.06)" },
  tag = "-default-opacity",
  opacity = "1 1",
})
