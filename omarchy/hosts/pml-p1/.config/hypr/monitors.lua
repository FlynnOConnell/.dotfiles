-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- A TV on the HDMI port or on a USB-C dongle (DP-n) is the main 1080p display
-- and the laptop screen copies it, like Windows' Duplicate. The other way
-- round, the 16:10 laptop picture reaches the 16:9 TV with black bars, and the
-- TV zooms in over them and cuts the edges off. Plugging the TV in or out
-- reloads this file, so the laptop screen follows.
local tv_outputs = { HDMI_A_1 = "HDMI-A-1", DP_1 = "DP-1", DP_2 = "DP-2", DP_3 = "DP-3" }
local tv_connected = nil
for _, monitor in ipairs(hl.get_monitors()) do
  for _, output in pairs(tv_outputs) do
    if monitor.name == output then
      tv_connected = output
    end
  end
end
for _, output in pairs(tv_outputs) do
  hl.monitor({ output = output, mode = "1920x1080@60", position = "auto", scale = 1 })
end
if tv_connected then
  hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = omarchy_monitor_scale, mirror = tv_connected })
end

local function reload_for_tv(monitor)
  local name = type(monitor) == "table" and monitor.name or tostring(monitor)
  for _, output in pairs(tv_outputs) do
    if name == output then
      hl.exec_cmd("hyprctl reload")
    end
  end
end
hl.on("monitor.added", reload_for_tv)
hl.on("monitor.removed", reload_for_tv)
