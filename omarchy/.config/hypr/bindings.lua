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

-- Vim-style focus movement (was: SUPER+J toggle split, SUPER+K keybindings, SUPER+L workspace layout).
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
o.bind("SUPER + H", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + L", "Focus on right window", hl.dsp.focus({ direction = "r" }))
o.bind("SUPER + K", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + J", "Focus on below window", hl.dsp.focus({ direction = "d" }))

-- Send the current workspace to the left/right monitor (shorter than SUPER+SHIFT+ALT+arrows).
o.bind("SUPER + ALT + H", "Move workspace to left monitor", hl.dsp.workspace.move({ monitor = "l" }))
o.bind("SUPER + ALT + L", "Move workspace to right monitor", hl.dsp.workspace.move({ monitor = "r" }))


-- Screen recording menu, or stop if recording (was: SUPER+SHIFT+P Google Photos).
hl.unbind("SUPER + SHIFT + P")
o.bind("SUPER + SHIFT + P", "Screenrecording", "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")
o.bind("SUPER + SHIFT + ALT + P", "Screenrecording (full screen)", "omarchy-capture-screenrecording --fullscreen")

-- PDF reader for papers (opens the last document; press o inside to pick another).
o.bind("SUPER + SHIFT + R", "PDF reader (Sioyek)", { launch = "sioyek" })

-- Work Outlook (UTSW) as web apps, focusing the existing window if open (was: HEY email/calendar).
hl.unbind("SUPER + SHIFT + E")
hl.unbind("SUPER + SHIFT + C")
hl.unbind("SUPER + SHIFT + ALT + E")
o.bind("SUPER + SHIFT + E", "Outlook Mail", "omarchy-launch-or-focus-webapp 'Mail.*Outlook' 'https://outlook.office.com/mail/'")
o.bind("SUPER + SHIFT + C", "Outlook Calendar", "omarchy-launch-or-focus-webapp 'Calendar.*Outlook' 'https://outlook.office.com/calendar/'")
o.bind("SUPER + SHIFT + ALT + E", "New Outlook email", { webapp = "https://outlook.office.com/mail/deeplink/compose" })

-- Stream the lab workstation (pml-w1) with Moonlight, focusing the stream if it's already open.
o.bind("SUPER + SHIFT + ALT + W", "pml-w1 (Moonlight)", "omarchy-launch-or-focus Moonlight 'uwsm-app -- moonlight stream 100.117.75.71 Desktop'")
