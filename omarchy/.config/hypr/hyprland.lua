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

-- Dell U4924DW (49", 5120x1440): the same settings on any machine it's plugged
-- into, found by its EDID description, so the port doesn't matter (a USB-C
-- DP-n on pml-p1). On it, the scratchpad (SUPER+S, where Slack
-- lives) tiles in the middle half of the screen instead of across all 49", and
-- regular workspaces use centered master: the main window in the middle half,
-- the rest stacked in the side columns.
-- A workspace filter can't hold the description (it has spaces), so the rules
-- name the port the monitor is on now, and the config reloads when it moves.
local ultrawide = "Dell Inc. Dell U4924DW HYK59B4"
hl.monitor({ output = "desc:" .. ultrawide, mode = "5120x1440@60", position = "auto", scale = 1.25 })

-- Centered master, wherever a workspace uses it: the middle column stays put even
-- with zero or one side window, and new windows open at the sides (Omarchy's
-- default puts each new window in the middle). SUPER+Z swaps one into the middle.
hl.config({
  master = { mfact = 0.5, slave_count_for_center_master = 0, always_keep_position = true, new_status = "slave" },
})

local function ultrawide_monitor()
  for _, monitor in ipairs(hl.get_monitors()) do
    if monitor.description == ultrawide then
      return monitor
    end
  end
end

local ultrawide_now = ultrawide_monitor()
if ultrawide_now then
  local side = math.floor(ultrawide_now.width / ultrawide_now.scale / 4)
  hl.workspace_rule({
    workspace = "n[s:special:scratchpad] m[" .. ultrawide_now.name .. "]",
    gaps_out = { top = 10, right = side, bottom = 10, left = side },
  })
  hl.workspace_rule({
    workspace = "m[" .. ultrawide_now.name .. "] s[false]",
    layout = "master",
    layout_opts = { orientation = "center" },
  })
  -- NOTE: this has to load before default.hypr.toggles, which restores the layouts
  -- saved per workspace by SUPER+ALT+L. Overlapping workspace rules apply in the
  -- order added, and re-adding a rule for the same workspace merges into the first
  -- one in place, so a saved layout only beats this rule if it was added after it.
end

local function reload_if_ultrawide_moved()
  local monitor = ultrawide_monitor()
  if (monitor and monitor.name) ~= (ultrawide_now and ultrawide_now.name) then
    hl.exec_cmd("hyprctl reload")
  end
end
hl.on("monitor.added", reload_if_ultrawide_moved)
hl.on("monitor.removed", reload_if_ultrawide_moved)

-- A host with no monitor streams a headless output named sunshine (home_hub's
-- headless-display). Once a real monitor is on, that output would keep its
-- workspaces where no screen shows them, so it goes and they move over.
local function drop_headless_stream_output()
  local headless, real = false, false
  for _, monitor in ipairs(hl.get_monitors()) do
    if monitor.name == "sunshine" then
      headless = true
    elseif monitor.name ~= "FALLBACK" then
      real = true
    end
  end
  if headless and real then
    hl.exec_cmd("hyprctl output remove sunshine")
  end
end
drop_headless_stream_output()
hl.on("monitor.added", drop_headless_stream_output)

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
-- gets its own key, SUPER+M: show and focus it, or from it hide it. It opens
-- from nvim (<leader>dm) and closes when that nvim quits, or on SUPER+W, which,
-- like SUPER+M, unmaps it while the app keeps running.
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

-- from the viewer to the window used before it (the editor), leaving it
-- shown; the app calls it after opening a file in nvim: hyprctl dispatch sciview.swap
function sciview.swap()
  local viewer = sciview_window()
  if not viewer or not viewer.active then
    return
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

-- show and focus the viewer (a hidden one through the app, which maps it);
-- when it's focused, hide it: a close request, which the app turns into a hide,
-- and Hyprland gives focus back to the window used before it (the editor)
function sciview.toggle()
  local viewer = sciview_window()
  if not viewer then
    return hl.exec_cmd("sciview show --focus")
  end
  if viewer.active then
    return hl.dispatch(hl.dsp.window.close({ window = "address:" .. viewer.address }))
  end
  sciview.reveal()
  sciview_focus(viewer)
end

hl.unbind("SUPER + M")
o.bind("SUPER + M", "sciview: show and focus / hide", sciview.toggle)

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

hl.unbind("SUPER + I")
o.bind("SUPER + I", "Images from nvim: show and focus / hide", swayimg_nvim.toggle)

-- Markdown preview from nvim (nvim/lua/config/markdown_preview.lua): a Chrome
-- app window on http://localhost:<port>/page/<bufnr>, rendered like VS Code's
-- preview. It lives on special:markdown-preview as a floating page over the
-- editor, opaque so the text reads true. nvim opens it on the machine it runs
-- on and on every machine watching it through a herdr remote client, so
-- SUPER+N switches between editor and preview wherever the keyboard is.
-- markdown_preview is global so nvim can call it: hyprctl eval 'markdown_preview.show()'
o.window({ class = "^chrome-localhost__page_[0-9]+-Default$" }, {
  workspace = "special:markdown-preview silent",
  float = true,
  size = { "(monitor_w*0.6)", "(monitor_h*0.94)" },
  center = true,
  tag = "-default-opacity",
  opacity = "1 1",
})

markdown_preview = { opened = {} }

local function markdown_preview_workspace()
  return hl.get_workspace("special:markdown-preview")
end

local function markdown_preview_showing()
  local special = markdown_preview_workspace()
  return special and special.visible
end

local function markdown_preview_has_windows()
  local special = markdown_preview_workspace()
  return special and special.windows > 0
end

-- nvim calls this for its preview server (port) whenever the preview is asked
-- for; a server already opened here is left alone while a window is still up.
-- host "" is this machine. For another host the page comes through an ssh
-- tunnel on the same port, which closes when that nvim (pid_nvim) exits.
function markdown_preview.open(host, port, bufnr, pid_nvim)
  local server = host .. ":" .. port
  if markdown_preview.opened[server] and markdown_preview_has_windows() then
    return
  end
  markdown_preview.opened[server] = true
  local launch = "omarchy-launch-webapp http://localhost:" .. port .. "/page/" .. bufnr
  if host == "" then
    return hl.exec_cmd(launch)
  end
  local forward = port .. ":localhost:" .. port
  local hold = "'tail --pid=" .. pid_nvim .. " -f /dev/null'"
  hl.exec_cmd("ssh -f -o BatchMode=yes -o ExitOnForwardFailure=yes -L " .. forward .. " " .. host .. " " .. hold .. " && " .. launch)
end

-- the silent rule keeps a window that is still starting up from opening the
-- workspace itself, so nvim opens it here and the window maps into view
function markdown_preview.show()
  if not markdown_preview_showing() then
    hl.dispatch(hl.dsp.workspace.toggle_special("markdown-preview"))
  end
end

-- hide a shown preview; show one that is running (nvim starts it)
function markdown_preview.toggle()
  if markdown_preview_showing() or markdown_preview_has_windows() then
    hl.dispatch(hl.dsp.workspace.toggle_special("markdown-preview"))
  end
end

o.bind("SUPER + N", "Markdown preview from nvim: show / hide", markdown_preview.toggle)

-- games open on workspace 4: CS2 (native) and Proton games (steam_app_<id>).
-- Fullscreen games and Chrome (xCloud) hold off the screensaver: controller input doesn't count as activity.
o.window({ class = "^(cs2|steam_app_[0-9]+)$" }, { workspace = "4", idle_inhibit = "fullscreen" })
o.window({ class = "^google-chrome$" }, { idle_inhibit = "fullscreen" })

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

-- Python GUIs (imgui_bundle, fastplotlib, Qt) float at the size they asked for
-- instead of tiling: hello_imgui lays its panels out for the size it requested,
-- and a tiled half screen breaks that layout. They come up through XWayland
-- (imgui_bundle ships an X11-only GLFW) with the window title as the class, so
-- no class rule covers them all; the process does. A window.open hook floats
-- any window whose process is a python from a uv venv (~/envs/<name>/.venv).
local function process_argv0(pid)
  local file = io.open("/proc/" .. pid .. "/cmdline", "r")
  if not file then return "" end
  local cmdline = file:read("*a") or ""
  file:close()
  local nul = cmdline:find("\0", 1, true)
  return nul and cmdline:sub(1, nul - 1) or cmdline
end

hl.on("window.open", function(window)
  if not window or window.floating or not window.pid or window.pid <= 0 then return end
  if process_argv0(window.pid):find("/.venv/bin/python", 1, true) then
    hl.dispatch(hl.dsp.window.float({ action = "on", window = "address:" .. window.address }))
  end
end)

-- Pop-over apps: each lives on its own special workspace as a floating,
-- near-fullscreen window over whatever is open. Its key starts the app if it
-- isn't running, shows it on the monitor the cursor is on, and hides it again
-- on the next press (the app keeps running). A window of the app that opened
-- elsewhere, or got dragged off, is pulled back onto its workspace first.
-- Web app classes are chrome-<host>_<path with / as _>-Default.
-- The workspace rule is silent: only the key shows the workspace, so a stray
-- window of the app cannot pop the workspace open and dim the screen.
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

-- Slack (was: SUPER+SHIFT+S Google Maps).
hl.unbind("SUPER + SHIFT + S")
popover("SUPER + SHIFT + S", "Slack", "slack", o.launch("slack"))

-- Steam runs on Omarchy's defaults (floating, 1100x700); the in-game overlay
-- (SHIFT+TAB) draws inside the game window, so it needs the game to keep focus.
-- Steam's message toasts (title notificationtoasts_<n>_desktop) are real X11
-- windows: pin them bottom-right and never give them focus, so a message
-- arriving mid-game shows without taking input from the game.
o.window({ class = "^steam$", title = "^notificationtoasts_" }, {
  float = true,
  pin = true,
  move = "monitor_w-w-16 monitor_h-h-16",
  no_focus = true,
  no_initial_focus = true,
  no_dim = true,
  no_anim = true,
})

-- Discord (was: SUPER+SHIFT+D Docker).
hl.unbind("SUPER + SHIFT + D")
popover("SUPER + SHIFT + D", "Discord", "chrome-discord.com__channels_@me-Default", o.launch_webapp("https://discord.com/channels/@me"))
-- Home Assistant over Tailscale, by MagicDNS name: HA rejects logins from a
-- 100.x IP as an invalid client id, since it doesn't count CGNAT as private.
popover("SUPER + SHIFT + A", "Home Assistant", "chrome-homeassistant.tail0ea452.ts.net__-Default", o.launch_webapp("http://homeassistant.tail0ea452.ts.net"))
hl.unbind("SUPER + SHIFT + T")
popover("SUPER + SHIFT + T", "Tailscale", "chrome-login.tailscale.com__admin_machines-Default", o.launch_webapp("https://login.tailscale.com/admin/machines"))
-- Quick note (was: SUPER+SHIFT+W Omawrite on an empty document): today's inbox
-- note in Obsidian (quick-note). Every show re-runs it, so a new day gets its
-- own file; every hide runs repo-sync, which commits and pushes the vault.
popover("SUPER + SHIFT + W", "Notes", "md.obsidian.Obsidian", "quick-note", { on_show = "quick-note", on_hide = "repo-sync" })
-- Opaque: text over other windows' text is unreadable through Omarchy's default opacity.
o.window({ class = "^md\\.obsidian\\.Obsidian$" }, { tag = "-default-opacity", opacity = "1 1" })
