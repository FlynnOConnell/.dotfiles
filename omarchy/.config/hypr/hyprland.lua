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
-- gets its own keys. It opens from nvim (<leader>dm) and closes when that nvim
-- quits, or on SUPER+W, which unmaps it while the app keeps running.
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

-- <leader>dm in nvim (the app calls it): a viewer on another workspace comes
-- back here; the app focuses it after
function sciview.reveal()
  local viewer = sciview_window()
  if viewer and not sciview_here(viewer) then
    sciview_move(viewer, tostring(hl.get_active_workspace().id))
  end
end

-- focus the viewer, or from it the window used before it (the editor),
-- leaving it shown; a closed viewer stays closed: nvim opens it
function sciview.swap()
  local viewer = sciview_window()
  if not viewer then
    return
  end
  if not viewer.active then
    sciview.reveal()
    return sciview_focus(viewer)
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

o.bind("SUPER + ALT + M", "sciview: focus it / back to the editor", sciview.swap)

-- swayimg-nvim (the image window nvim opens images in, nvim/lua/config/swayimg.lua):
-- floats where sciview does, without taking focus from the editor, opaque so
-- figures show true colors. Hidden means parked on special:swayimg-nvim.
-- swayimg_nvim is global so nvim can call it: hyprctl dispatch swayimg_nvim.reveal
o.window({ class = "^swayimg-nvim$" }, {
  float = true,
  no_initial_focus = true,
  size = { "(monitor_w*0.55)", "(monitor_h*0.88)" },
  move = { "(monitor_w*0.43)", "(monitor_h*0.06)" },
  tag = "-default-opacity",
  opacity = "1 1",
})

swayimg_nvim = {}

local function swayimg_nvim_move(viewer, workspace)
  hl.dispatch(hl.dsp.window.move({ workspace = workspace, follow = false, window = "address:" .. viewer.address }))
end

-- nvim calls this on every image it sends: a hidden window (or one on
-- another workspace) comes back here, leaving focus in the editor
function swayimg_nvim.reveal()
  local viewer = hl.get_windows({ class = "swayimg-nvim" })[1]
  if viewer and viewer.workspace.id ~= hl.get_active_workspace().id then
    swayimg_nvim_move(viewer, tostring(hl.get_active_workspace().id))
  end
end

-- show and focus the image window (to zoom or step through the folder); when
-- it's focused, hide it. It's started by opening an image in nvim.
function swayimg_nvim.toggle()
  local viewer = hl.get_windows({ class = "swayimg-nvim" })[1]
  if not viewer then
    return
  end
  if viewer.active then
    return swayimg_nvim_move(viewer, "special:swayimg-nvim")
  end
  swayimg_nvim.reveal()
  hl.dispatch(hl.dsp.focus({ window = "address:" .. viewer.address }))
end

o.bind("SUPER + I", "Images from nvim: show and focus / hide", swayimg_nvim.toggle)

-- games open on workspace 4: CS2 (native) and Proton games (steam_app_<id>)
o.window({ class = "^(cs2|steam_app_[0-9]+)$" }, { workspace = "4" })

-- No window gets focus just by asking for it (Omarchy's default says yes). The
-- terminal running herdr/Claude asks whenever a notification goes through it,
-- which yanked focus out of CS2 mid-match. The asker gets the urgent flag (a
-- border flash) instead, and SUPER+<n> still goes there on purpose.
hl.config({ misc = { focus_on_activate = false } })

-- Silence notifications while a game has focus; put them back when it loses
-- it. Only the hook's own silencing is undone, so DND the user turned on by
-- hand (SUPER+CTRL+comma) stays on after a match.
-- (Lua patterns have no alternation, so one pattern per game class.)
local game_classes = { "^cs2$", "^steam_app_%d+$" }
function fo_is_game(window)
  if not (window and window.class) then return false end
  for _, pattern in ipairs(game_classes) do
    if window.class:match(pattern) then return true end
  end
  return false
end
fo_game_silenced = false -- global so `hyprctl eval` can sync it
hl.on("window.active", function(window)
  local in_game = fo_is_game(window)
  if in_game and not fo_game_silenced then
    fo_game_silenced = true
    hl.exec_cmd("omarchy-shell notifications setDnd on && omarchy-shell -q omarchy.indicators refresh")
  elseif not in_game and fo_game_silenced then
    fo_game_silenced = false
    hl.exec_cmd("omarchy-shell notifications setDnd off && omarchy-shell -q omarchy.indicators refresh")
  end
end)

-- Pop-over apps: each lives on its own special workspace as a floating,
-- near-fullscreen window over whatever is open. Its key starts the app if it
-- isn't running, shows it on the monitor the cursor is on, and hides it again
-- on the next press (the app keeps running). A window of the app that opened
-- elsewhere, or got dragged off, is pulled back onto its workspace first.
-- Web app classes are chrome-<host>_<path with / as _>-Default.
-- The workspace rule is silent: only the key shows the workspace, so a stray
-- window of the app (a Steam toast whose title isn't set yet when it maps)
-- cannot pop the workspace open and dim the screen.
-- hooks.on_show runs on every show of a running app, hooks.on_hide on every hide.
-- hooks.match adds fields to the window-rule match (e.g. a title exclusion).
local function popover_toggle(name, class, launch, hooks)
  local special = hl.get_workspace("special:" .. name)
  local window = hl.get_windows({ class = class })[1]
  local showing = special and special.visible
  if not window then
    if not showing then
      hl.exec_cmd(launch)
    end
  elseif not (window.workspace and window.workspace.name == "special:" .. name) then
    hl.dispatch(hl.dsp.window.move({ workspace = "special:" .. name, follow = false, window = "address:" .. window.address }))
  end
  if showing and hooks.on_hide then
    hl.exec_cmd(hooks.on_hide)
  elseif window and not showing and hooks.on_show then
    hl.exec_cmd(hooks.on_show)
  end
  hl.dispatch(hl.dsp.workspace.toggle_special(name))
end

local function popover(keys, description, class, launch, hooks)
  hooks = hooks or {}
  local name = description:lower():gsub("%s+", "-")
  local match = { class = "^" .. class:gsub("%.", "\\.") .. "$" }
  for key, value in pairs(hooks.match or {}) do
    match[key] = value
  end
  o.window(match, {
    workspace = "special:" .. name .. " silent",
    float = true,
    size = { "(monitor_w*0.96)", "(monitor_h*0.94)" },
    center = true,
  })
  o.bind(keys, description .. ": show / hide", function()
    popover_toggle(name, class, launch, hooks)
  end)
end

-- Steam (was: SUPER+SHIFT+S Google Maps); games still open on workspace 4.
-- Its notification toasts are excluded here and handled below.
hl.unbind("SUPER + SHIFT + S")
popover("SUPER + SHIFT + S", "Steam", "steam", o.launch("steam"), { match = { title = "negative:^notificationtoasts_" } })

-- Steam's notification toasts ("friend is online", title
-- notificationtoasts_<n>_desktop) are real X11 windows. The Steam rule above
-- used to drop them on special:steam, which opened that workspace, dimmed the
-- screen (dim_special) and took focus mid-game. Two modes, switched with
-- `steam-popups`:
--   popup (default): the toast pins bottom-right of the current monitor as a
--     quiet floating card; nothing gets focus and no workspace opens.
--   sound: the toast stays hidden on special:steam and a sound plays.
local steam_toast = { class = "^steam$", title = "^notificationtoasts_" }
local steam_toast_hidden = hl.window_rule({
  name = "steam-toast-hidden",
  match = steam_toast,
  workspace = "special:steam silent",
  float = true,
  no_focus = true,
  no_initial_focus = true,
  no_dim = true,
  no_anim = true,
})
local steam_toast_popup = hl.window_rule({
  name = "steam-toast-popup",
  match = steam_toast,
  float = true,
  pin = true,
  move = "monitor_w-w-16 monitor_h-h-16",
  no_focus = true,
  no_initial_focus = true,
  no_dim = true,
  no_anim = true,
})
local steam_toast_sound_flag = os.getenv("HOME") .. "/.local/state/omarchy/toggles/steam-toast-sound"
fo_steam_popups_on = true
function fo_steam_popups_sync()
  local flag = io.open(steam_toast_sound_flag, "r")
  fo_steam_popups_on = flag == nil
  if flag then flag:close() end
  steam_toast_hidden:set_enabled(not fo_steam_popups_on)
  steam_toast_popup:set_enabled(fo_steam_popups_on)
end
fo_steam_popups_sync()
hl.on("window.open", function(window)
  if not window or window.class ~= "steam" then return end
  local title = window.title or window.initial_title or ""
  local log = io.open(os.getenv("HOME") .. "/.local/state/omarchy/steam-windows.log", "a")
  if log then
    local size = type(window.size) == "table" and (tostring(window.size[1]) .. "x" .. tostring(window.size[2])) or tostring(window.size)
    log:write(os.date("%Y-%m-%d %H:%M:%S"), "\ttitle=", title, "\tinitial_title=", tostring(window.initial_title), "\tsize=", size, "\n")
    log:close()
  end
  if fo_steam_popups_on then return end
  if title:match("^notificationtoasts_") then
    hl.exec_cmd("pw-play /usr/share/sounds/freedesktop/stereo/message.oga")
  end
end)

-- Discord (was: SUPER+SHIFT+D Docker).
hl.unbind("SUPER + SHIFT + D")
popover("SUPER + SHIFT + D", "Discord", "chrome-discord.com__channels_@me-Default", o.launch_webapp("https://discord.com/channels/@me"))
-- Home Assistant over Tailscale, by MagicDNS name: HA rejects logins from a
-- 100.x IP as an invalid client id, since it doesn't count CGNAT as private.
popover("SUPER + SHIFT + A", "Home Assistant", "chrome-homeassistant.tail0ea452.ts.net__-Default", o.launch_webapp("http://homeassistant.tail0ea452.ts.net"))
popover("SUPER + SHIFT + T", "Tailscale", "chrome-login.tailscale.com__admin_machines-Default", o.launch_webapp("https://login.tailscale.com/admin/machines"))
-- Quick note (was: SUPER+SHIFT+W Omawrite on an empty document): today's inbox
-- note in Obsidian (quick-note). Every show re-runs it, so a new day gets its
-- own file; every hide runs repo-sync, which commits and pushes the vault.
popover("SUPER + SHIFT + W", "Notes", "md.obsidian.Obsidian", "quick-note", { on_show = "quick-note", on_hide = "repo-sync" })
-- Opaque: text over other windows' text is unreadable through Omarchy's default opacity.
o.window({ class = "^md\\.obsidian\\.Obsidian$" }, { tag = "-default-opacity", opacity = "1 1" })
