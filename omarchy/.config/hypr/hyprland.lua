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

-- SUPER+H/J/K/L never cross between tiled and floating windows, so the viewer
-- gets its own keys. Hidden means parked on special:sciview, which is never
-- shown; closing the window (SUPER+W) unmaps it, and the app keeps running.
-- sciview is global so the app can call it: hyprctl dispatch sciview.reveal
sciview = {}

local function sciview_window()
  return hl.get_windows({ class = "sciview" })[1]
end

local function sciview_here(viewer)
  return viewer.workspace.id == hl.get_active_workspace().id
end

local function sciview_move(viewer, workspace)
  hl.dispatch(hl.dsp.window.move({ workspace = workspace, follow = false, window = "address:" .. viewer.address }))
end

local function sciview_focus(window)
  hl.dispatch(hl.dsp.focus({ window = "address:" .. window.address }))
end

-- ,m in nvim (the app calls it): a hidden viewer (or one on another
-- workspace) comes back here, leaving focus in the editor
function sciview.reveal()
  local viewer = sciview_window()
  if viewer and not sciview_here(viewer) then
    sciview_move(viewer, tostring(hl.get_active_workspace().id))
  end
end

-- show and focus the viewer; when it's focused, hide it
function sciview.toggle()
  local viewer = sciview_window()
  if not viewer then
    -- closed or never shown: the app shows it (systemd starts the app first)
    return hl.exec_cmd("sciview show --focus")
  end
  if viewer.active then
    return sciview_move(viewer, "special:sciview")
  end
  sciview.reveal()
  sciview_focus(viewer)
end

-- focus the viewer, or from it the window used before it, leaving it shown
function sciview.swap()
  local viewer = sciview_window()
  if not (viewer and viewer.active) then
    return sciview.toggle()
  end
  local previous
  for _, window in ipairs(hl.get_workspace_windows(viewer.workspace.id)) do
    if window.address ~= viewer.address and (not previous or window.focus_history_id < previous.focus_history_id) then
      previous = window
    end
  end
  if previous then
    sciview_focus(previous)
  end
end

o.bind("SUPER + M", "sciview: show and focus / hide", sciview.toggle)
o.bind("SUPER + ALT + M", "sciview: focus it / back to the editor", sciview.swap)

-- games open on workspace 4: CS2 (native) and Proton games (steam_app_<id>)
o.window({ class = "^(cs2|steam_app_[0-9]+)$" }, { workspace = "4" })
