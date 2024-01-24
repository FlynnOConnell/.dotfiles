local awful = require('awful')
require('awful.autofocus')
local beautiful = require('beautiful')
local hotkeys_popup = require('awful.hotkeys_popup').widget

local modkey = require('configuration.keys.mod').modKey
local altkey = require('configuration.keys.mod').altKey
local apps = require('configuration.apps')

-- Key bindings
local globalKeys =
awful.util.table.join(

  -- ----------------------------------------------------------------
  -- General --------------------------------------------------------
  -- ----------------------------------------------------------------
  awful.key({modkey}, 'F1', hotkeys_popup.show_help, {description = 'Show help', group = 'awesome'}),
  awful.key({modkey}, 'u', awful.client.urgent.jumpto, {description = 'jump to urgent client', group = 'client'}),
  awful.key({modkey}, 'p', awful.tag.viewprev, {description = 'view previous', group = 'tag'}),
  awful.key({modkey}, 'n', awful.tag.viewnext, {description = 'view next', group = 'tag'}),
  awful.key({modkey}, 'Escape', awful.tag.history.restore, {description = 'go back', group = 'tag'}),
  awful.key({altkey}, 'space', function() awful.spawn('rofi -combi-modi window,drun -show combi -modi combi') end, {description = 'Show main menu', group = 'awesome'}), awful.key( {modkey, 'Shift'}, 'q', function() _G.exit_screen_show() end, {description = 'Log Out Screen', group = 'awesome'}),

  awful.key({modkey}, "h",     function() awful.client.focus.bydirection("left") if client.focus then client.focus:raise() end end),
  awful.key({modkey}, "j",     function() awful.client.focus.bydirection("down") if client.focus then client.focus:raise() end end),
  awful.key({modkey}, "k",     function() awful.client.focus.bydirection("up") if client.focus then client.focus:raise() end end),
  awful.key({modkey}, "l",     function() awful.client.focus.bydirection("right") if client.focus then client.focus:raise() end end),

  -- ----------------------------------------------------------------
  -- Programms ------------------------------------------------------

  -- Region Screenshot
  awful.key(
    {altkey, 'Shift'},
    'p',
    function()
      awful.util.spawn_with_shell(apps.default.region_screenshot)
    end,
    {description = 'Mark an area and screenshot it to your clipboard', group = 'screenshots (clipboard)'}
  ),

  -- Firefox / Web Browser
  awful.key(
    {modkey, 'Shift'},
    'f',
    function()
      awful.util.spawn(apps.default.browser)
    end,
    {description = 'Open a browser', group = 'launcher'}
  ),

  awful.key({modkey, 'Control'}, 'r', _G.awesome.restart, {description = 'reload awesome', group = 'awesome'}),

  -- Switch between last focused window / slave and master,
  awful.key({modkey, 'Shift', 'Control'}, 'q', _G.awesome.quit, {description = 'quit awesome', group = 'awesome'}),
  awful.key(
    {modkey, 'Control'},
    'n',
    function()
      local c = awful.client.restore()
      -- Focus restored client
      if c then
	_G.client.focus = c
	c:raise()
      end
    end,
    {description = 'restore minimized', group = 'client'}
  ),

  -- Standard program
  awful.key(
    {modkey, 'Shift'},
    't',
    function()
      awful.spawn(apps.default.terminal)
    end,
    {description = 'Terminal', group = 'launcher'}
  ),
  -- Dropdown application
  awful.key(
    {modkey},
    'z',
    function()
      _G.toggle_quake()
    end,
    {description = 'dropdown application', group = 'launcher'}
  ),

  -- File Manager
  awful.key(
    {modkey},
    'e',
    function()
      awful.util.spawn(apps.default.files)
    end,
    {description = 'filebrowser', group = 'hotkeys'}
  )
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
  -- Hack to only show tags 1 and 9 in the shortcut window (mod+s)
  local descr_view, descr_toggle, descr_move, descr_toggle_focus
  if i == 1 or i == 9 then
    descr_view = {description = 'view tag #', group = 'tag'}
    descr_toggle = {description = 'toggle tag #', group = 'tag'}
    descr_move = {description = 'move focused client to tag #', group = 'tag'}
    descr_toggle_focus = {description = 'toggle focused client on tag #', group = 'tag'}
  end
  globalKeys =
  awful.util.table.join(
    globalKeys,
    -- View tag only.
    awful.key(
      {modkey},
      '#' .. i + 9,
      function()
	local screen = awful.screen.focused()
	local tag = screen.tags[i]
      if tag then
	  tag:view_only()
	end
      end,
      descr_view
    ),
    -- Toggle tag display.
    awful.key(
      {modkey, 'Control'},
      '#' .. i + 9,
      function()
	local screen = awful.screen.focused()
	local tag = screen.tags[i]
      if tag then
	  awful.tag.viewtoggle(tag)
	end
      end,
      descr_toggle
    ),
    -- Move client to tag.
    awful.key(
      {modkey, 'Shift'},
      '#' .. i + 9,
      function()
	if _G.client.focus then
	  local tag = _G.client.focus.screen.tags[i]
	if tag then
	    _G.client.focus:move_to_tag(tag)
	  end
	end
      end,
      descr_move
    ),
    -- Toggle tag on focused client.
    awful.key(
      {modkey, 'Control', 'Shift'},
      '#' .. i + 9,
      function()
	if _G.client.focus then
	  local tag = _G.client.focus.screen.tags[i]
	if tag then
	    _G.client.focus:toggle_tag(tag)
	  end
	end
      end,
      descr_toggle_focus
    )
  )
end

--
-- awful.key(
--   {modkey},
--   'Right',
--   function()
--     awful.tag.incmwfact(0.05)
--   end,
--   {description = 'Increase master width factor', group = 'layout'}
-- ),
-- awful.key(
--   {modkey},
--   'Left',
--   function()
--     awful.tag.incmwfact(-0.05)
--   end,
--   {description = 'Decrease master width factor', group = 'layout'}
-- ),
-- awful.key(
--   {modkey},
--   'Down',
--   function()
--     awful.client.incwfact(0.05)
--   end,
--   {description = 'Decrease master height factor', group = 'layout'}
-- ),
-- awful.key(
--   {modkey},
--   'Up',
--   function()
--     awful.client.incwfact(-0.05)
--   end,
--   {description = 'Increase master height factor', group = 'layout'}
-- ),
-- awful.key(
--   {modkey, 'Shift'},
--   'Right',
--   function()
--     awful.tag.incnmaster(1, nil, true)
--   end,
--   {description = 'Increase the number of master clients', group = 'layout'}
-- ),
-- awful.key(
--   {modkey, 'Shift'},
--   'Left',
--   function()
--     awful.tag.incnmaster(-1, nil, true)
--   end,
--   {description = 'Decrease the number of master clients', group = 'layout'}
-- ),
-- awful.key(
--   {modkey, 'Control'},
--   'Right',
--   function()
--     awful.tag.incncol(1, nil, true)
--   end,
--   {description = 'Increase the number of columns', group = 'layout'}
-- ),
-- awful.key(
--   {modkey, 'Control'},
--   'Left',
--   function()
--     awful.tag.incncol(-1, nil, true)
--   end,
--   {description = 'Decrease the number of columns', group = 'layout'}
-- ),
return globalKeys
