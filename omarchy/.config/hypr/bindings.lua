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


-- Screen recording menu, or stop if recording (was: SUPER+SHIFT+P Google Photos).
hl.unbind("SUPER + SHIFT + P")
o.bind("SUPER + SHIFT + P", "Screenrecording", "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")
o.bind("SUPER + SHIFT + ALT + P", "Screenrecording (full screen)", "omarchy-capture-screenrecording --fullscreen")

-- Apps I use, on keys Omarchy gave to ones I don't (was: SUPER+SHIFT+M Spotify,
-- D Docker, G Signal, A ChatGPT). Each focuses its window if it's already open;
-- Slack is usually parked on the scratchpad, which comes up with it.
hl.unbind("SUPER + SHIFT + M")
hl.unbind("SUPER + SHIFT + D")
hl.unbind("SUPER + SHIFT + G")
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + M", "Slack", { launch = "slack.desktop", focus = "^slack$" })
-- Discord (SUPER+SHIFT+D) shows and hides like Steam; both are in hyprland.lua.
o.bind("SUPER + SHIFT + G", "GitLab", { webapp = "https://gitlab.com/dashboard/projects", focus = true })
o.bind("SUPER + SHIFT + H", "Home Assistant", { webapp = "http://100.85.105.1", focus = true })
o.bind("SUPER + SHIFT + T", "Tailscale", { webapp = "https://login.tailscale.com/admin/machines", focus = true })
-- Found by window class: "Claude" also turns up in other windows' titles.
o.bind("SUPER + SHIFT + A", "Claude", "omarchy-launch-or-focus-webapp chrome-claude https://claude.ai")

-- PDF reader for papers (opens the last document; press o inside to pick another).
o.bind("SUPER + SHIFT + R", "PDF reader (Sioyek)", { launch = "sioyek" })

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

-- Moonlight: tiled on workspace 3 instead of omarchy's forced fullscreen.
o.window("com.moonlight_stream.Moonlight", { fullscreen = false, tile = true, workspace = "3" })

-- Moonlight keyboard mode: toggles whether keys go to the stream or to this machine
-- (Moonlight's own Ctrl+Alt+Shift+Z). dont_inhibit so it still fires while Moonlight
-- has the keyboard grabbed. Needs Moonlight's "Capture system keyboard shortcuts" on
-- Always, which install-omarchy.sh sets.
o.bind("SUPER + Z", "Moonlight: toggle keys local/remote", function()
  local moonlight = hl.get_windows({ class = "com.moonlight_stream.Moonlight" })[1]
  if not moonlight then
    return
  end
  hl.dispatch(hl.dsp.focus({ window = "address:" .. moonlight.address }))
  hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL ALT SHIFT", key = "Z", state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL ALT SHIFT", key = "Z", state = "up" }))
  end, { timeout = 50, type = "oneshot" })
end, { dont_inhibit = true })

-- Herdr agents panel (the fo.herdr bar widget): what every agent is doing, Enter jumps to one.
o.bind("SUPER + A", "Herdr agents", "omarchy-shell fo.herdr toggle")
