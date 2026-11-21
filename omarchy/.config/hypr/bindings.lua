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

-- Swap the focused window with its neighbor (Omarchy has this on SUPER+SHIFT+arrows).
-- What these keys held before moved to SUPER+ALT below.
o.bind("SUPER + SHIFT + H", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + L", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))

-- Arrows resize instead of focusing (= and - are awkward on the split keyboard).
-- RIGHT / LEFT grow / shrink the focused window in any layout, repeating while held;
-- UP / DOWN widen / narrow the whole workspace in four steps down to the 16:9 box the
-- screen-share picker offers. SHIFT goes 300 px, or all the way. Replaces Omarchy's
-- focus and swap binds on these keys.
hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")
hl.unbind("SUPER + SHIFT + LEFT")
hl.unbind("SUPER + SHIFT + RIGHT")
hl.unbind("SUPER + SHIFT + UP")
hl.unbind("SUPER + SHIFT + DOWN")
o.bind("SUPER + RIGHT", "Grow window", "window-resize grow 100", { repeating = true })
o.bind("SUPER + LEFT", "Shrink window", "window-resize shrink 100", { repeating = true })
o.bind("SUPER + SHIFT + RIGHT", "Grow window a lot", "window-resize grow 300", { repeating = true })
o.bind("SUPER + SHIFT + LEFT", "Shrink window a lot", "window-resize shrink 300", { repeating = true })
o.bind("SUPER + UP", "Widen workspace", "workspace-width widen")
o.bind("SUPER + DOWN", "Narrow workspace toward the 16:9 share box", "workspace-width narrow")
o.bind("SUPER + SHIFT + UP", "Workspace at full width", "workspace-width widen 4")
o.bind("SUPER + SHIFT + DOWN", "Workspace in the 16:9 share box", "workspace-width narrow 4")

-- Workspace layout on SUPER+ALT+L: cycles dwindle, scrolling, centered master and
-- present, the 16:9 share box (Omarchy's toggle only flips the first two). Dwindle's
-- split toggle on SUPER+ALT+J; SUPER+Z is master's swap-into-the-middle. The
-- keybindings viewer is gone: the SUPER+CTRL+K cheatsheets menu lists Omarchy's keys.
hl.unbind("SUPER + ALT + L")
o.bind("SUPER + ALT + L", "Cycle workspace layout", "workspace-layout-cycle")
o.bind("SUPER + ALT + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + Z", "Swap window into the middle (centered master)", hl.dsp.layout("swapwithmaster"))
-- One menu for every cheat sheet (Omarchy, Herdr, Tmux, Neovim, web apps); was: Herdr keybindings.
hl.unbind("SUPER + CTRL + K")
o.bind("SUPER + CTRL + K", "Cheatsheets", "cheatsheets")
o.bind("SUPER + CTRL + SHIFT + S", "Switch monitor and KVM to the other computer", "kvm-switch")

-- One monitor only: drop Omarchy's move-workspace-to-monitor and monitor focus keys.
hl.unbind("SUPER + SHIFT + ALT + LEFT")
hl.unbind("SUPER + SHIFT + ALT + RIGHT")
hl.unbind("SUPER + SHIFT + ALT + UP")
hl.unbind("SUPER + SHIFT + ALT + DOWN")
hl.unbind("CTRL + ALT + TAB")
hl.unbind("CTRL + ALT + SHIFT + TAB")


-- Screenshot on SUPER+P, same flow as PRINT. Pseudo-tile moves to SUPER+ALT+P.
hl.unbind("SUPER + P")
o.bind("SUPER + P", "Screenshot", "omarchy-capture-screenshot")
o.bind("SUPER + ALT + P", "Pseudo window", hl.dsp.window.pseudo())

-- Record the focused monitor, no audio; again to stop and open the folder on the new file
-- (was: SUPER+SHIFT+P Google Photos).
hl.unbind("SUPER + SHIFT + P")
o.bind("SUPER + SHIFT + P", "Screenrecording: start / stop", "screenrecord-toggle")

-- Apps I use, on keys Omarchy gave to ones I don't (was: SUPER+SHIFT+M Spotify,
-- G Signal, A ChatGPT). Slack focuses its window if it's already open. Slack,
-- Discord, Home Assistant and Tailscale (SUPER+SHIFT+S/D/A/T) are pop-overs in hyprland.lua.
hl.unbind("SUPER + SHIFT + M")
hl.unbind("SUPER + SHIFT + G")
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + M", "Slack", { launch = "slack.desktop", focus = "^slack$" })

-- Tiled web apps on one key each: the first press opens the app, a press while
-- another window has focus brings it up, and a press while it is focused closes
-- it. The pop-overs in hyprland.lua hide and keep running instead; these are
-- cheap to reopen, so they close. Chrome names an app window
-- chrome-<host>__<path with / as _>-Default, from the URL it was launched with.
local function webapp_class(url)
  local host, path = url:gsub("^%w+://", ""):match("^([^/]+)/?(.*)$")
  return "chrome-" .. host .. "__" .. path:gsub("/", "_") .. "-Default"
end

local function window_toggle(class, launch_command)
  local window = hl.get_windows({ class = class })[1]
  local active = hl.get_active_window()
  if not window then
    hl.exec_cmd(launch_command)
  elseif active and active.address == window.address then
    hl.dispatch(hl.dsp.window.close({ window = "address:" .. window.address }))
  else
    hl.dispatch(hl.dsp.focus({ window = "address:" .. window.address }))
  end
end

function fo_webapp_toggle(url) -- global so `hyprctl eval` can drive it
  window_toggle(webapp_class(url), o.launch_webapp(url))
end

local function webapp(keys, description, url)
  o.bind(keys, description .. ": open / close", function()
    fo_webapp_toggle(url)
  end)
end

webapp("SUPER + SHIFT + G", "GitLab", "https://gitlab.com/dashboard/projects")
webapp("SUPER + ALT + H", "Claude", "https://claude.ai")
webapp("SUPER + CTRL + G", "pml-w1 results", "https://pml-w1.tail0ea452.ts.net/")

-- GitHub in a full Chrome window (URL bar, tabs), which a --app window cannot
-- have. Its own data dir makes it a separate Chrome with the window class
-- "github"; --class is ignored by a Chrome that shares the main profile. The
-- page keys open a tab in that window, starting it if needed.
local github_class = "github"
local github_chrome = "uwsm-app -- google-chrome-stable --user-data-dir="
  .. os.getenv("HOME")
  .. "/.config/google-chrome-github --class="
  .. github_class
  .. " --no-first-run "

local function github_page(keys, description, url)
  o.bind(keys, "GitHub: " .. description, function()
    hl.exec_cmd(github_chrome .. "'" .. url .. "'")
    local window = hl.get_windows({ class = github_class })[1]
    if window then
      hl.dispatch(hl.dsp.focus({ window = "address:" .. window.address }))
    end
  end)
end

o.bind("SUPER + ALT + O", "GitHub: open / close", function()
  window_toggle(github_class, github_chrome .. "https://github.com/FlynnOConnell")
end)
github_page("SUPER + ALT + M", "masknmf-toolbox", "https://github.com/apasarkar/masknmf-toolbox")
github_page("SUPER + ALT + E", "my repos", "https://github.com/FlynnOConnell?tab=repositories")

-- PDF reader for papers (opens the last document; press o inside to pick another).
-- Through XWayland: on native Wayland its OpenGL context fails (EGL_BAD_MATCH on
-- pml-w2's NVIDIA) and it runs with no window.
o.bind("SUPER + SHIFT + R", "PDF reader (Sioyek)", { launch = "env QT_QPA_PLATFORM=xcb sioyek" })

-- Work Outlook (UTSW) as web apps (was: HEY email/calendar).
hl.unbind("SUPER + SHIFT + E")
hl.unbind("SUPER + SHIFT + C")
hl.unbind("SUPER + SHIFT + ALT + E")
webapp("SUPER + SHIFT + E", "Outlook Mail", "https://outlook.office.com/mail/")
webapp("SUPER + SHIFT + C", "Outlook Calendar", "https://outlook.office.com/calendar/")
o.bind("SUPER + SHIFT + ALT + E", "New Outlook email", { webapp = "https://outlook.office.com/mail/deeplink/compose" })

-- The bar's calendar, with Google Calendar events (the fo.clock plugin), in
-- place of universal copy.
hl.unbind("SUPER + C")
o.bind("SUPER + C", "Calendar", "omarchy-shell shell toggle omarchy.clock")

-- Stream a lab workstation with Moonlight, focusing that host's stream if it's already open.
o.bind("SUPER + R", "pml-w1 (Moonlight)", "moonlight-stream pml-w1")

-- Quick note (SUPER+SHIFT+W, was: Omawrite on an empty document) is a pop-over in hyprland.lua.
hl.unbind("SUPER + SHIFT + W")

-- Record a meeting as your mic and everyone else in separate files; again to stop.
o.bind("SUPER + CTRL + M", "Meeting recording: start / stop", "meeting-record")

-- Moonlight: on workspace 3, fullscreen by omarchy's own rule.
o.window("com.moonlight_stream.Moonlight", { workspace = "3" })

-- Moonlight keyboard and mouse: SUPER+D hands both to the stream or back to this machine
-- (Moonlight's own Ctrl+Alt+Shift+Z); from another window it jumps to the stream and hands
-- them over. dont_inhibit so it still fires while Moonlight has the keyboard grabbed. Needs
-- Moonlight's "Capture system keyboard shortcuts" on Always (install-omarchy.sh) and
-- "Optimize mouse for remote desktop" on (home_hub's install-hub.sh, as mouseacceleration=true).
-- The second puts the remote cursor where this one is, without a pointer lock, and keeps
-- the grab when the stream loses focus.
--
-- While the stream has them it carries the moonlight-remote tag, and while it's also focused
-- a dark green frame (the fo.stream-frame shell plugin) circles its monitor: fullscreen
-- windows have no border. Hyprland doesn't expose the grab, so the tag follows Moonlight's
-- own rules: it grabs when the stream starts or is clicked into.
local moonlight_class = "com.moonlight_stream.Moonlight"

local function moonlight_is_remote(moonlight)
  for _, tag in ipairs(moonlight.tags) do
    if tag == "moonlight-remote" then
      return true
    end
  end
  return false
end

-- Starts unknown so the first call after a config reload always syncs the shell.
local moonlight_frame_monitor = nil

local function update_moonlight_frame()
  local window = hl.get_active_window()
  local monitor = ""
  if window and window.class == moonlight_class and moonlight_is_remote(window) then
    monitor = window.monitor.name
  end
  if monitor ~= moonlight_frame_monitor then
    moonlight_frame_monitor = monitor
    hl.exec_cmd(monitor == "" and "omarchy-shell -q fo.stream-frame hide" or "omarchy-shell -q fo.stream-frame show " .. monitor)
  end
end

local function set_moonlight_remote(moonlight, remote)
  if remote ~= moonlight_is_remote(moonlight) then
    hl.dispatch(hl.dsp.window.tag({ tag = (remote and "+" or "-") .. "moonlight-remote", window = "address:" .. moonlight.address }))
  end
  update_moonlight_frame()
end

-- A plain bind on the same key fires only when the focused window isn't grabbing the
-- keyboard, and Hyprland runs it before the toggle below, so the toggle can read where
-- keys were going instead of trusting the tag.
local keys_were_local = false
hl.bind("SUPER + D", function()
  keys_were_local = true
end)

o.bind("SUPER + D", "Moonlight: keys and mouse to the stream / back here", function()
  local was_local = keys_were_local
  keys_were_local = false
  local moonlight = hl.get_windows({ class = moonlight_class })[1]
  if not moonlight then
    return
  end
  -- Unfocused, the stream keeps the grab it had and the tag is all there is to go on;
  -- a stream that kept it only needs focus to have the keys again.
  local was_remote = moonlight_is_remote(moonlight)
  if moonlight.active then
    was_remote = not was_local
  end
  local remote = not (moonlight.active and was_remote)
  hl.dispatch(hl.dsp.focus({ window = "address:" .. moonlight.address }))
  if remote ~= was_remote then
    hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL ALT SHIFT", key = "Z", state = "down" }))
    hl.timer(function()
      hl.dispatch(hl.dsp.send_key_state({ mods = "CTRL ALT SHIFT", key = "Z", state = "up" }))
    end, { timeout = 50, type = "oneshot" })
  end
  set_moonlight_remote(moonlight, remote)
end, { dont_inhibit = true })

hl.on("window.open", function(window)
  if window.class == moonlight_class and window.initial_title:find(" %- Moonlight$") then
    set_moonlight_remote(window, true)
  end
end)

hl.on("window.active", update_moonlight_frame)

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
hl.unbind("SUPER + A")
o.bind("SUPER + A", "Herdr agents", "omarchy-shell fo.herdr toggle")

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end
