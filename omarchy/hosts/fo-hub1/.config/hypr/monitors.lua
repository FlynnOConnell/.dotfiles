-- fo-hub1: always-on HEADLESS hub (no physical display).
-- Create a virtual Hyprland output at login so there is a surface for
-- Sunshine/Moonlight to capture. Change the mode to match your usual client.
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

local HEADLESS_MODE = "2560x1440@60"

-- Any real output (there are none here) gets sane defaults; harmless if absent.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })

-- Ensure exactly one headless output exists and is sized. Retried because the
-- compositor may not be ready the instant hyprland.start fires.
local make_headless = string.format([[for i in $(seq 20); do
  out=$(hyprctl monitors all -j | jq -r '[.[] | select(.name|test("HEADLESS"))][0].name // empty')
  if [ -z "$out" ]; then hyprctl output create headless >/dev/null 2>&1; sleep 0.3; continue; fi
  hyprctl keyword monitor "$out,%s,0x0,1" >/dev/null 2>&1
  break
done]], HEADLESS_MODE)

hl.on("hyprland.start", function() hl.exec_cmd(make_headless) end)
