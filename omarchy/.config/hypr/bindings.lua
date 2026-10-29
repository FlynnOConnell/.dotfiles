-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Herdr on SUPER+RETURN; a plain terminal moves to SUPER+CTRL+RETURN, where Herdr was.
-- SUPER+SHIFT+RETURN stays Omarchy's browser, which is Chrome (the xdg default).
hl.unbind("SUPER + RETURN")
hl.unbind("SUPER + CTRL + RETURN")
o.bind("SUPER + RETURN", "Herdr", { omarchy = "terminal-herdr" })
o.bind("SUPER + CTRL + RETURN", "Terminal", { omarchy = "terminal" })

-- Vim-style focus movement (was: SUPER+J toggle split, SUPER+K keybindings, SUPER+L workspace layout).
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
o.bind("SUPER + H", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + L", "Focus on right window", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + K", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + J", "Focus on below window", hl.dsp.focus({ direction = "d" }))

-- Workspace layout toggle, moved off SUPER+L.
o.bind("SUPER + SHIFT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")
-- Dwindle split toggle and the keybindings viewer, moved off SUPER+J and SUPER+K.
o.bind("SUPER + SHIFT + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + SHIFT + K", "Keybindings", "omarchy-menu-keybindings")

-- Send the current workspace to the left/right monitor (shorter than SUPER+SHIFT+ALT+arrows).
o.bind("SUPER + ALT + H", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + ALT + L", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))
-- Same on SUPER+SHIFT+arrows (was: swap window left/right).
hl.unbind("SUPER + SHIFT + LEFT")
hl.unbind("SUPER + SHIFT + RIGHT")
o.bind("SUPER + SHIFT + LEFT", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + SHIFT + RIGHT", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))


-- Screenshot on SUPER+P, same flow as PRINT. Pseudo-tile moves to SUPER+ALT+P.
hl.unbind("SUPER + P")
o.bind("SUPER + P", "Screenshot", "omarchy-capture-screenshot")
o.bind("SUPER + ALT + P", "Pseudo window", hl.dsp.window.pseudo())

-- Record the focused monitor, no audio; again to stop (was: SUPER+SHIFT+P Google Photos).
hl.unbind("SUPER + SHIFT + P")
o.bind("SUPER + SHIFT + P", "Screenrecording: start / stop", "omarchy-capture-screenrecording --stop-recording || omarchy-capture-screenrecording --fullscreen")

-- Apps I use, on keys Omarchy gave to ones I don't (was: SUPER+SHIFT+M Spotify,
-- G Signal, A ChatGPT). Each focuses its window if it's already open; Slack is
-- usually parked on the scratchpad, which comes up with it. Steam, Discord,
-- Home Assistant and Tailscale (SUPER+SHIFT+S/D/A/T) are pop-overs in hyprland.lua.
hl.unbind("SUPER + SHIFT + M")
hl.unbind("SUPER + SHIFT + G")
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + M", "Slack", { launch = "slack.desktop", focus = "^slack$" })
o.bind("SUPER + SHIFT + G", "GitLab", { webapp = "https://gitlab.com/dashboard/projects", focus = true })
-- Found by window class: "Claude" also turns up in other windows' titles.
o.bind("SUPER + SHIFT + H", "Claude", "omarchy-launch-or-focus-webapp chrome-claude https://claude.ai")
-- By window class too: the title changes to whichever report is open.
o.bind("SUPER + CTRL + G", "pml-w1 results", "omarchy-launch-or-focus-webapp chrome-pml-w1 https://pml-w1.tail0ea452.ts.net/")

-- PDF reader for papers (opens the last document; press o inside to pick another).
-- Through XWayland: on native Wayland its OpenGL context fails (EGL_BAD_MATCH on
-- pml-w2's NVIDIA) and it runs with no window.
o.bind("SUPER + SHIFT + R", "PDF reader (Sioyek)", { launch = "env QT_QPA_PLATFORM=xcb sioyek" })

-- Work Outlook (UTSW) as web apps, focusing the existing window if open (was: HEY email/calendar).
hl.unbind("SUPER + SHIFT + E")
hl.unbind("SUPER + SHIFT + C")
hl.unbind("SUPER + SHIFT + ALT + E")
o.bind("SUPER + SHIFT + E", "Outlook Mail", "omarchy-launch-or-focus-webapp 'Mail.*Outlook' 'https://outlook.office.com/mail/'")
o.bind("SUPER + SHIFT + C", "Outlook Calendar", "omarchy-launch-or-focus-webapp 'Calendar.*Outlook' 'https://outlook.office.com/calendar/'")
o.bind("SUPER + SHIFT + ALT + E", "New Outlook email", { webapp = "https://outlook.office.com/mail/deeplink/compose" })

-- Stream a lab workstation with Moonlight, focusing that host's stream if it's already open.
o.bind("SUPER + R", "pml-w1 (Moonlight)", "moonlight-stream 100.117.75.71")
o.bind("SUPER + ALT + R", "pml-w2 (Moonlight)", "moonlight-stream 100.77.145.99")

-- Quick note (SUPER+SHIFT+W, was: Omawrite on an empty document) is a pop-over in hyprland.lua.
hl.unbind("SUPER + SHIFT + W")

-- Record a meeting as your mic and everyone else in separate files; again to stop.
o.bind("SUPER + CTRL + M", "Meeting recording: start / stop", "meeting-record")

-- Moonlight: tiled on workspace 3 instead of omarchy's forced fullscreen.
o.window("com.moonlight_stream.Moonlight", { fullscreen = false, tile = true, workspace = "3" })

-- Moonlight keyboard mode: toggles whether keys go to the stream or to this machine
-- (Moonlight's own Ctrl+Alt+Shift+Z). dont_inhibit so it still fires while Moonlight
-- has the keyboard grabbed. Needs Moonlight's "Capture system keyboard shortcuts" on
-- Always, which install-omarchy.sh sets.
--
-- While the stream has the keyboard it carries the moonlight-remote tag and a white
-- border; otherwise it keeps the theme's border. Hyprland doesn't expose the grab, so the
-- tag follows Moonlight's own rules: it grabs when the stream starts or is clicked into,
-- and lets go on focus loss unless fullscreen. Fullscreen windows have no border at all.
local moonlight_class = "com.moonlight_stream.Moonlight"
o.window({ tag = "moonlight-remote" }, { border_color = "rgb(ffffff)" })

local function moonlight_is_remote(moonlight)
  for _, tag in ipairs(moonlight.tags) do
    if tag == "moonlight-remote" then
      return true
    end
  end
  return false
end

local function set_moonlight_remote(moonlight, remote)
  if remote ~= moonlight_is_remote(moonlight) then
    hl.dispatch(hl.dsp.window.tag({ tag = (remote and "+" or "-") .. "moonlight-remote", window = "address:" .. moonlight.address }))
  end
end

-- A plain bind on the same key fires only when the focused window isn't grabbing the
-- keyboard, and Hyprland runs it before the toggle below, so the toggle can read where
-- keys were going instead of trusting the tag.
local keys_were_local = false
hl.bind("SUPER + GRAVE", function()
  keys_were_local = true
end)

o.bind("SUPER + GRAVE", "Moonlight: toggle keys local/remote", function()
  local was_local = keys_were_local
  keys_were_local = false
  local moonlight = hl.get_windows({ class = moonlight_class })[1]
  if not moonlight then
    return
  end
  -- An unfocused stream can't grab, so there the tag is all there is to go on.
  local was_remote = moonlight_is_remote(moonlight)
  if moonlight.active then
    was_remote = not was_local
  end
  hl.dispatch(hl.dsp.focus({ window = "address:" .. moonlight.address }))
  hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL ALT SHIFT", key = "Z", state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL ALT SHIFT", key = "Z", state = "up" }))
  end, { timeout = 50, type = "oneshot" })
  set_moonlight_remote(moonlight, not was_remote)
end, { dont_inhibit = true })

hl.on("window.open", function(window)
  if window.class == moonlight_class and window.initial_title:find(" %- Moonlight$") then
    set_moonlight_remote(window, true)
  end
end)

hl.on("window.active", function(window)
  local moonlight = hl.get_windows({ class = moonlight_class })[1]
  if moonlight and not (window and window.address == moonlight.address) and moonlight.fullscreen_client < 2 then
    set_moonlight_remote(moonlight, false)
  end
end)

-- Non-consuming and inhibitable, so it only sees clicks the stream isn't already grabbing.
hl.bind("mouse:272", function()
  local moonlight = hl.get_active_window()
  if not moonlight or moonlight.class ~= moonlight_class then
    return
  end
  local cursor = hl.get_cursor_pos()
  local inside_x = cursor.x >= moonlight.at.x and cursor.x < moonlight.at.x + moonlight.size.x
  local inside_y = cursor.y >= moonlight.at.y and cursor.y < moonlight.at.y + moonlight.size.y
  if inside_x and inside_y then
    set_moonlight_remote(moonlight, true)
  end
end, { non_consuming = true })

-- Herdr agents panel (the fo.herdr bar widget): what every agent is doing, Enter jumps to one.
o.bind("SUPER + A", "Herdr agents", "omarchy-shell fo.herdr toggle")
