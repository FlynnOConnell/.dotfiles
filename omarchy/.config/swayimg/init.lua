-- swayimg (image viewer). See /usr/share/swayimg/example.lua for every option.
-- Vim-style keys on top of the defaults; ? lists them here, and so do nvim's
-- cheatsheet (SPC k) and the stub nvim shows for an image. Keep the three in
-- step: KEYS below, the Images section of nvim/cheatsheet.md.

-- PgDown/PgUp step through the rest of the image's folder.
swayimg.imagelist.adjacent = true

local KEYS = table.concat({
  "j k      next / previous image      g G    first / last",
  "H J K L  pan                        + -    zoom (or scroll)",
  "0 w z    100% / fit width / fit     Enter  gallery",
  "y Y      copy image / its path      o      show in Files",
  "r        reload from disk           t f    info / fullscreen",
  "q Esc    hide                       Q      quit",
}, "\n")

swayimg.viewer.text = {
  topleft = { "File:\t{name}", "Format:\t{format}", "File size:\t{sizehr}", "File time:\t{time}" },
  topright = { "Image:\t{list.index} of {list.total}", "Size:\t{frame.width}x{frame.height}" },
  bottomleft = { "Scale:\t{scale}" },
  bottomright = { "? keys" },
}

local function say(message, seconds)
  swayimg.text.status_timeout = seconds or 2
  swayimg.text.status = message
end

local function sh(command)
  os.execute(command .. " >/dev/null 2>&1 &")
end

local function quote(s)
  return "'" .. (s:gsub("'", "'\\''")) .. "'"
end

-- q/Esc: the window nvim opens images in hides (as SUPER+I does in
-- hyprland.lua) so it keeps its folder; any other swayimg quits
local function hide()
  if swayimg.appid == "swayimg-nvim" then
    sh("hyprctl dispatch swayimg_nvim.toggle")
  else
    swayimg.exit()
  end
end

local function copy_path(image)
  sh("wl-copy -- " .. quote(image.path))
  say("Copied " .. image.path)
end

local function show_in_files(image)
  sh("uwsm-app -- nautilus --select " .. quote(image.path))
end

-- the frame as shown, as PNG, so SVGs and other formats paste anywhere
local function copy_image()
  local png = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/swayimg-copy.png"
  swayimg.viewer.export(png)
  sh("wl-copy --type image/png < " .. quote(png))
  say("Copied image")
end

-- move the image a tenth of the window
local function pan(dx, dy)
  local pos, size = swayimg.viewer.get_position(), swayimg.get_window_size()
  swayimg.viewer.set_abs_position(pos.x + math.floor(dx * size.width / 10), pos.y + math.floor(dy * size.height / 10))
end

local function zoom(factor, at_mouse)
  local scale = swayimg.viewer.scale * factor
  if at_mouse then
    local mouse = swayimg.get_mouse_pos()
    swayimg.viewer.set_abs_scale(scale, mouse.x, mouse.y)
  else
    swayimg.viewer.set_abs_scale(scale)
  end
end

local viewer = swayimg.viewer
viewer.on_key("j", function() viewer.open("next") end)
viewer.on_key("k", function() viewer.open("prev") end)
viewer.on_key("g", function() viewer.open("first") end)
viewer.on_key("Shift+g", function() viewer.open("last") end)
viewer.on_key("Shift+h", function() pan(1, 0) end)
viewer.on_key("Shift+l", function() pan(-1, 0) end)
viewer.on_key("Shift+k", function() pan(0, 1) end)
viewer.on_key("Shift+j", function() pan(0, -1) end)
viewer.on_key({ "equal", "plus", "Shift+plus", "KP_Add" }, function() zoom(1.1) end)
viewer.on_key({ "minus", "KP_Subtract" }, function() zoom(1 / 1.1) end)
viewer.on_mouse("ScrollUp", function() zoom(1.1, true) end)
viewer.on_mouse("ScrollDown", function() zoom(1 / 1.1, true) end)
viewer.on_key("0", function() viewer.set_fix_scale("real") end)
viewer.on_key("w", function() viewer.set_fix_scale("width") end)
viewer.on_key("z", function() viewer.set_fix_scale("fit") end)
viewer.on_key("y", copy_image)
viewer.on_key("Shift+y", function() copy_path(viewer.get_image()) end)
viewer.on_key("o", function() show_in_files(viewer.get_image()) end)
viewer.on_key("r", function()
  viewer.reload()
  say("Reloaded")
end)
viewer.on_key({ "q", "Escape" }, hide)
viewer.on_key("Shift+q", swayimg.exit)
viewer.on_key({ "Shift+question", "question" }, function() say(KEYS, 8) end)

local gallery = swayimg.gallery
gallery.on_key("h", function() gallery.select("left") end)
gallery.on_key("j", function() gallery.select("down") end)
gallery.on_key("k", function() gallery.select("up") end)
gallery.on_key("l", function() gallery.select("right") end)
gallery.on_key("g", function() gallery.select("first") end)
gallery.on_key("Shift+g", function() gallery.select("last") end)
gallery.on_key("Shift+y", function() copy_path(gallery.get_image()) end)
gallery.on_key("o", function() show_in_files(gallery.get_image()) end)
gallery.on_key({ "q", "Escape" }, hide)
gallery.on_key("Shift+q", swayimg.exit)
gallery.on_key({ "Shift+question", "question" }, function() say(KEYS, 8) end)

-- The window nvim opens images in (appid swayimg-nvim, see
-- nvim/lua/config/swayimg.lua): nvim writes the image's path to
-- $XDG_RUNTIME_DIR/swayimg-nvim and sends SIGUSR1. swayimg only catches
-- SIGUSR1 once its window is up, and before that the signal kills it, so the
-- pid file nvim signals is written only after startup.
if swayimg.appid == "swayimg-nvim" then
  local request = (os.getenv("XDG_RUNTIME_DIR") or "/tmp") .. "/swayimg-nvim"

  local function requested()
    local file = io.open(request)
    if not file then
      return nil
    end
    local path = file:read("l")
    file:close()
    return path ~= "" and path or nil
  end

  local function open_requested()
    local path = requested()
    if path then
      swayimg.mode = "viewer"
      swayimg.viewer.open_path(path)
    end
  end

  swayimg.viewer.on_signal("USR1", open_requested)
  swayimg.slideshow.on_signal("USR1", open_requested)
  swayimg.gallery.on_signal("USR1", open_requested)

  swayimg.on_initialized(function()
    -- an image nvim sent while this window was starting
    local path = requested()
    if path and path ~= swayimg.viewer.get_image().path then
      swayimg.viewer.open_path(path)
    end
    local stat = io.open("/proc/self/stat")
    local pid = stat:read("n")
    stat:close()
    local pidfile = io.open(request .. ".pid", "w")
    pidfile:write(pid)
    pidfile:close()
  end)
end
