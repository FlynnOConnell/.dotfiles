-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- AOC defaults to 60 Hz; run it at its full 144 Hz
hl.monitor({ output = "desc:AOC AG241QG4 0x0000029C", mode = "2560x1440@143.91", position = "auto", scale = 1 })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- games workspace lives on the right monitor (AOC 1440p)
hl.workspace_rule({ workspace = "4", monitor = "desc:AOC AG241QG4 0x0000029C", default = true })

-- workspace 2 lives on the left monitor (Acer 1080p)
hl.workspace_rule({ workspace = "2", monitor = "desc:Acer Technologies SA243Y P1 6615092813W01" })

-- Proton games size fullscreen to the XWayland primary output, and with none
-- set Wine falls back to the Acer at 0x0 (Rocket League only offered 1080p).
-- Mark the AOC primary at login and whenever a monitor reconnects; retried
-- because XWayland may not have the output yet.
local aoc_primary = [[for i in $(seq 20); do
  out=$(hyprctl monitors -j | jq -r '.[] | select(.description == "AOC AG241QG4 0x0000029C") | .name')
  [ -n "$out" ] && DISPLAY=${DISPLAY:-:0} xrandr --output "$out" --primary 2>/dev/null && break
  sleep 0.5
done]]
hl.on("hyprland.start", function() hl.exec_cmd(aoc_primary) end)
hl.on("monitor.added", function() hl.exec_cmd(aoc_primary) end)
