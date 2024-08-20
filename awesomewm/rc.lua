
-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
local wibox = require("wibox")
local beautiful = require("beautiful")
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")


-- used for bash commands and executables that have very little to no observable effect
local function _spawn_cmd(cmd)
	awful.spawn.with_line_callback(cmd, {
		stderr = function(line)
			naughty.notify({ text = "["..cmd.." stderr] "..line})
		end,
		stdout = function(line)
			naughty.notify({ text = "["..cmd.." stdout] "..line})
		end,
	})
end

local function _screenshot(b_select)
	-- TODO: there are more useful switches in those utilities
	-- TODO: I can probably use pipe instead of temporary file
	local FILE = "/tmp/screenshot.png"
	local flag_select = b_select and "--select" or ""
	local cmd = "bash -c \"rm -rf "..FILE.." && scrot --freeze "..flag_select.." --file "..FILE.." && xclip -selection clipboard -t image/png -i "..FILE.."\""
	_spawn_cmd(cmd)
end

-- NOTE: I had way too many hacky if-else statements. I abstracted away everything to this place.
--     Changing those values is super easy now, though I wouldn't say the same about adding new functionality...
local CLIENT_STATES = {
	{ key="_none", transition="maximized", border_width=5, b_mouse_movable=true, b_allow_wholescreen=false, b_allow_offscreen=false, },
	{ key="fullscreen", transition="maximized", border_width=0, b_mouse_movable=false, b_allow_wholescreen=true, b_allow_offscreen=true, },
	{ key="ontop", transition="_none", border_width=1, b_mouse_movable=true, b_allow_wholescreen=false, b_allow_offscreen=true, },
	{ key="maximized", transition="_none", border_width=2, b_mouse_movable=false, b_allow_wholescreen=true, b_allow_offscreen=false, },
	{ key="floating", transition="_none", border_width=5, b_mouse_movable=true, b_allow_wholescreen=false, b_allow_offscreen=true, },
}

local function _client_state_get(c)
	for _, val in pairs(CLIENT_STATES) do
		if c[val.key] == true then
			return val
		end
	end
	-- WARN: this should be unreachable
	-- but nothing bad will happen if ever hit
	return CLIENT_STATES[1]
end

local function _client_states_bind(func)
	for _,val in pairs(CLIENT_STATES) do
		client.connect_signal("property::"..val.key, func)
	end
end

client.connect_signal("property::ontop", function(c)
	c.opacity = c.ontop and 0.8 or 1
end)

-- Prevents some client states from covering whole screen space
--     so the user won't confuse them with actual states that should cover the screen.
local function _client_prevent_wholescreen (c)
	local state = _client_state_get(c)
	if state.b_allow_wholescreen then return end
	local screen_bouding = c.screen:get_bounding_geometry({
		honor_padding  = true,
		honor_workarea = true,
	})
	-- WARN: hardcoded value
	local ALLOWED = 0.9
	local allowed_width = ALLOWED * screen_bouding.width
	if c.width > allowed_width then
		c.width = allowed_width
		c.x = screen_bouding.width * (1-ALLOWED) / 2 + screen_bouding.x
	end
	local allowed_height = ALLOWED * screen_bouding.height
	if c.height > allowed_height then
		c.height = allowed_height
		c.y = screen_bouding.height * (1-ALLOWED) / 2 + screen_bouding.y
	end
end
_client_states_bind(_client_prevent_wholescreen)

-- Prevents clients from persisting outside of visible screen area.
local function _client_prevent_offscreen(c)
	local state = _client_state_get(c)
	if state.b_allow_offscreen then return end
	awful.placement.no_offscreen(c)
end
client.connect_signal("manage", _client_prevent_offscreen)
client.connect_signal("focus", _client_prevent_offscreen)
_client_states_bind(_client_prevent_offscreen)

-- Manages how border width behaves under centrain conditions
local function _client_resolve_border_width (c)
	local state = _client_state_get(c)
	local border_width_new = state.border_width * beautiful.border_width
	-- NOTE: Following code fixes gaps that appear
	--     due to applying smaller border width right after changing client size.
	local border_width_old = c.border_width
	if border_width_new ~= border_width_old then
		c.border_width = border_width_new
		local border_width_diff = border_width_old - border_width_new
		c.width = c.width + 2 * border_width_diff
		c.height = c.height + 2 * border_width_diff
	end
end
_client_states_bind(_client_resolve_border_width)
-- NOTE: this signal here is required - therwise client will be cutoff after maximizing
-- PERF: though, using additional signal is probably not performant
client.connect_signal("property::size", _client_resolve_border_width)
client.connect_signal("manage", _client_resolve_border_width)

-- Manages how border color behaves under centrain conditions
local function _client_resolve_border_color (c)
	c.border_color =
		(client.focus == c) and beautiful.border_focus
		or true and beautiful.border_normal
end
client.connect_signal("focus", _client_resolve_border_color)
client.connect_signal("unfocus", _client_resolve_border_color)


local function _client_state_toggle(c, state_key)
	-- WARN: This code has bugs, but this is intentional!
	-- In the worst case, user may need to press key twice.
	-- This is better than asserting inside of call and blocking state transition.
	-- PERF: also... this could be a bit faster... but FCK IT!
	local current_state = _client_state_get(c)
	for _,val in pairs(CLIENT_STATES) do
		if c[val.key] == true then
			c[val.key] = false
		end
	end
	if current_state.key == state_key then
		local transition = current_state.transition
		c[transition] = true
	else
		c[state_key] = true
	end
	c:raise()
end

local function _client_on_mouse_manipulate (c)
	local state = _client_state_get(c)
	if not state.b_mouse_movable then
		for _,val in pairs(CLIENT_STATES) do
			if val.b_mouse_movable == true then
				_client_state_toggle(c, val.key)
				break
			end
			assert(false)
		end
	end
	c:emit_signal("request::activate", "mouse_click", {raise = true})
end

local function _screen_wallpaper_resolve(s)
	gears.wallpaper.set(beautiful.fg_focus)
end
screen.connect_signal("property::geometry", _screen_wallpaper_resolve)


-- {{{ Error handling
-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
	naughty.notify({
		preset = naughty.config.presets.critical,
		title = "Oops, there were errors during startup!",
		text = awesome.startup_errors
	})
end
-- Handle runtime errors after startup
do
	local in_error = false
	awesome.connect_signal("debug::error", function (err)
		-- Make sure we don't go into an endless error loop
		if in_error then return end
		in_error = true
		naughty.notify({
			preset = naughty.config.presets.critical,
			title = "Oops, an error happened!",
			text = tostring(err)
		})
		in_error = false
	end)
end
-- }}}

-- {{{ Variable definitions
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
beautiful.font = "Iosevka Nerd Font Mono, Regular 15"
beautiful.tasklist_plain_task_name=true

-- Gruvbox <3
beautiful.bg_normal     = "#3c3836"
beautiful.bg_focus      = "#a89984"
beautiful.bg_urgent     = "#fb4934"
beautiful.bg_minimize   = "#282828"
beautiful.fg_normal     = "#bdae93"
beautiful.fg_focus      = "#1d2021"
beautiful.fg_urgent     = beautiful.fg_focus
beautiful.fg_minimize   = beautiful.fg_normal
beautiful.border_normal = beautiful.fg_focus
beautiful.border_focus  = beautiful.bg_focus
beautiful.border_marked = beautiful.bg_urgent
beautiful.bg_systray    = beautiful.bg_normal

local hostname = os.getenv("HOSTNAME")
local TERMINAL = hostname == "DEAL260624" and "lxterminal" or "wezterm"
local KEY_SUPER = "Mod4"
local BAR_HEIGHT = 35

beautiful.wibar_height = BAR_HEIGHT
-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
	awful.layout.suit.floating,
}
-- }}}


-- Menubar configuration
menubar.utils.terminal = TERMINAL
menubar.show_categories = false
menubar.geometry = {
	x = 0,
	y = 0,
	height = BAR_HEIGHT,
}
menubar.prompt_args.prompt = " Run: "
-- }}}


-- {{{ Wibar

-- aur/awesome-git uses lua5.4 but lain-git is installed as lua5.3 package
package.path = package.path .. ";/usr/share/lua/5.3/?/init.lua;/usr/share/lua/5.3/?.lua;/usr/share/lua/5.3/lain/?.lua"
-- most of the widgets below are taken from lain: https://github.com/lcpz/lain
-- FIXME: Lain widgets are super simple, most are under 200 lines, I should just write them on my own some day
local lain = require("lain")

local function _format_percentage(usage)
	-- value always have to be 2-digits long, otherwise widgets will move
	usage = tonumber(usage)
	if usage > 99 then
		return "99"
	elseif usage < 10 then
		return " "..tostring(usage)
	else
		return tostring(usage)
	end
end

local mycpu = lain.widget.cpu({
	settings = function()
		-- FIXME: lain.widget.cpu seems useless as it does not support diplaying cpu clocks...
		-- https://github.com/lcpz/lain/pull/552
		local text = "| CPU ".._format_percentage(cpu_now.usage).."% {"
		for i = 1, #cpu_now do
			local usage = cpu_now[i].usage
			local sign =
				usage >= 95 and 'M'
				or usage <= 5 and '_'
				-- divide by 10 and round like in math
				or tostring(math.floor(0.5 + usage/10))
				or "ERR"
			text = text..sign
		end
		text = text.."} "
		widget:set_markup(text)
	end
})
mycpu.widget:buttons(awful.util.table.join(
	awful.button({}, 1, function() -- left click
		awful.spawn(TERMINAL.." -e htop")
	end),
	nil
))

local mymem = lain.widget.mem({
	settings = function()
		local text = "| Mem ".._format_percentage(mem_now.perc).."% "
		MIB_TO_GB = 0.001048576
		local used;
		used = mem_now.used * MIB_TO_GB
		used = string.format("%.1f", used)
		used = tonumber(used)
		used = used > 10 and used or " "..tostring(used)
		-- used = #used > 4 and used or tostring(used).."0"
		text = text..tostring(used).."GB "
		widget:set_markup(text)
	end
})
mymem.widget:buttons(awful.util.table.join(
	awful.button({}, 1, function() -- left click
		awful.spawn(TERMINAL.." -e htop")
	end),
	nil
))

local myvol = lain.widget.pulse({
	settings = function()
		local muted = volume_now.muted == "yes"
		local l = volume_now.left
		local r = volume_now.right
		local value =
			muted and "MUT"
			or l==r and tostring(l)..'%'
			or l~=r and tostring(l)..'%/'..tostring(r)..'%'
			or "ERR"
		local text = "| Vol "..value.." "
		widget:set_markup(text)
	end
})
myvol.widget:buttons(awful.util.table.join(
	awful.button({}, 1, function() -- left click
		awful.spawn(TERMINAL.." -e pulsemixer")
	end),
	awful.button({}, 2, function() -- middle click
		_spawn_cmd(string.format("pactl set-sink-volume %s 100%%", myvol.device))
		myvol.update()
	end),
	awful.button({}, 3, function() -- right click
		_spawn_cmd(string.format("pactl set-sink-mute %s toggle", myvol.device))
		myvol.update()
	end),
	awful.button({}, 4, function() -- scroll up
		_spawn_cmd(string.format("pactl set-sink-volume %s +1%%", myvol.device))
		myvol.update()
	end),
	awful.button({}, 5, function() -- scroll down
		_spawn_cmd(string.format("pactl set-sink-volume %s -1%%", myvol.device))
		myvol.update()
	end)
))

local mydisk = lain.widget.fs({
	settings  = function()
		local partition = fs_now["/"]
		local percentage = tostring(partition.percentage)
		local text = "| Disk "..percentage.."% |"
		widget:set_text(text)
	end
})
mydisk.widget:buttons(awful.util.table.join(
	awful.button({}, 1, function() -- left click
		awful.spawn(TERMINAL.." -e ncdu /")
	end),
	nil
))

local mynet = lain.widget.net({
	notify = "on",
	wifi_state = "on",
	eth_state = "on",
	settings = function()
		local text = ""
		for _,val in pairs(net_now.devices) do
			-- FIXME: this does not work well with NetworkManager
			-- and shows Enternet/WIFI despite those being disabled
			if val.carrier == "0" then
				-- CONTINUE
			elseif val.ethernet then
				text = text.." Ethernet |"
			elseif val.wifi then
				local signal = val.signal
				text = text.." WiFi "
				---@diagnostic disable-next-line: cast-local-type
				text =
					false
					or signal <  -83 and text.."weak "
					or signal <  -70 and text.." mid "
					or signal <  -53 and text.." good"
					or signal >= -53 and text.."great"
					or text.."ERROR"
				text = text.." |"
			end
		end
		if text == "" then
			text = " NO NET |"
		end
		widget:set_markup(text)
	end
})
mynet.widget:buttons(awful.util.table.join(
	awful.button({}, 1, function() -- left click
		awful.spawn(TERMINAL.." -e nmtui connect")
	end),
	awful.button({}, 3, function() -- right click
		awful.spawn(TERMINAL.." -e nmtui")
	end),
	nil
))


local mytextclock = wibox.widget.textclock()
-- https://docs.gtk.org/glib/method.DateTime.format.html
mytextclock:set_format(" %a %d.%m.%y | %H:%M |")


-- set up the screen
awful.screen.connect_for_each_screen(function(s)
	_screen_wallpaper_resolve(s)
	-- there must be at least one tag, the one that is currently being used
	awful.tag({ "",}, s, awful.layout.layouts[1])
	-- Create a tasklist widget
	s.mytasklist = awful.widget.tasklist({
		screen  = s,
		filter  = awful.widget.tasklist.filter.currenttags,
		-- Left Mouse Button behavior
		buttons = gears.table.join(awful.button(
			{ }, 1,
			function (c)
				if c == client.focus then
					c.minimized = true
				else
					c:emit_signal( "request::activate", "tasklist", {raise = true})
				end
			end
		)),
		-- TODO: it would be nice to be able to move the client position on tasklist
	})
	s.mywibox = awful.wibar({ position = "top", screen = s })
	s.mywibox:setup({
		layout = wibox.layout.align.horizontal,
		{ -- Left widgets
			layout = wibox.layout.fixed.horizontal,
		},
		s.mytasklist, -- Middle widget
		{ -- Right widgets
			layout = wibox.layout.fixed.horizontal,
			mymem.widget,
			mycpu.widget,
			myvol.widget,
			mydisk.widget,
			mynet.widget,
			mytextclock,
			wibox.widget.systray(),
		},
	})

end)
-- }}}


-- {{{ Key bindings
local globalkeys = gears.table.join(
	awful.key({KEY_SUPER, "Shift" }, "q", function () awesome.quit() end, {description = "quit AwesomeWM", group = "screenshot"}),
	awful.key({KEY_SUPER}, "F1", hotkeys_popup.show_help, {description="show help", group="awesome"}),
	awful.key({KEY_SUPER}, "k", function () awful.client.focus.byidx(1) end, {description = "focus next by index", group = "client"}),
	awful.key({KEY_SUPER}, "j", function () awful.client.focus.byidx(-1) end, {description = "focus previous by index", group = "client"}),
	awful.key({KEY_SUPER}, "Return", function () awful.spawn(TERMINAL) end, {description = "open a terminal", group = "launcher"}),
	awful.key({KEY_SUPER}, "c", function () awful.spawn("chromium") end, {description = "open chromium", group = "launcher"}),
	awful.key({KEY_SUPER}, "i", function () awful.spawn(TERMINAL.." -e nvim") end, {description = "open neovim", group = "launcher"}),
	awful.key({KEY_SUPER}, "r", awesome.restart, {description = "restart awesome", group = "awesome"}),
	awful.key({KEY_SUPER}, "p", function() menubar.show() end, {description = "show the menubar", group = "launcher"}),
	awful.key({KEY_SUPER, "Shift" }, "s", function () _screenshot(true) end, {description = "capture screenshot of the screen selection", group = "screenshot"}),
	awful.key({KEY_SUPER}, "s", function () _screenshot(false) end, {description = "capture screenshot", group = "screenshot"}),
	awful.key({}, "Print", function () _screenshot(false) end, {description = "capture screenshot", group = "screenshot"}),
	-- TODO: this needs special treatment to make it more like in Windows and mainstream DEs, there should be clasic Alt+Tab
	-- TODO: make special functionality for win+tab, something that makes everything appear so I could pick it with mouse
	awful.key(
		{KEY_SUPER, "Shift" }, "n",
		function ()
			local c = awful.client.restore()
			if not c then return end
			c:emit_signal( "request::activate", "key.unminimize", {raise = true})
		end,
		{description = "restore minimized", group = "client"}
	),
	nil
)
root.keys(globalkeys)

-- TODO: it's probably better to set it globally without hooking to client
--     since all clients use this anyway.
local clientkeys = gears.table.join(
	awful.key({KEY_SUPER}, "q", function (c) c:kill() end, {description = "kill", group = "client"}),
	awful.key(
		{KEY_SUPER}, "n",
		function (c) c.minimized = true end ,
		{description = "minimize", group = "client"}
	),
	awful.key(
		{KEY_SUPER}, "o",
		function (c) _client_state_toggle(c, "ontop") end,
		{description = "toggle on-top", group = "client"}
	),
	awful.key(
		{KEY_SUPER}, "f",
		function (c) _client_state_toggle(c, "_none") end,
		{description = "toggle 'none'", group = "client"}
	),
	awful.key(
		{KEY_SUPER}, "m",
		function (c) _client_state_toggle(c, "maximized") end,
		{description = "toggle maximized", group = "client"}
	),
	awful.key(
		{}, "F11",
		function (c) _client_state_toggle(c, "fullscreen") end,
		{description = "toggle fullscreen", group = "client"}
	),
	nil
)

-- set how windows react with mouse
-- TODO: it's probably better to set it globally without hooking to client
--     since all clients use this anyway.
local clientbuttons = gears.table.join(
	awful.button({}, 1, function (c) c:emit_signal("request::activate", "mouse_click", {raise = true}) end),
	awful.button(
		{KEY_SUPER}, 1,
		function (c)
			-- FIXME: make it snap to cursor (omg... this is hard, I tried this already...)
			_client_on_mouse_manipulate(c)
			awful.mouse.client.move(c)
		end
	),
	awful.button(
		{KEY_SUPER}, 3,
		function (c)
			-- FIXME: it irritates me a lot that mouse snaps to the client's corner while resizing
			_client_on_mouse_manipulate(c)
			awful.mouse.client.resize(c)
		end
	)
)
-- }}}

-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
	{
		rule = { },
		properties = {
			focus = true,
			raise = true,
			keys = clientkeys,
			buttons = clientbuttons,
			screen = awful.screen.preferred,
			placement = awful.placement.no_overlap+awful.placement.no_offscreen,
			titlebars_enabled = false,
		},
	},
}

-- https://www.reddit.com/r/awesomewm/comments/owi4ki/comment/hhjga1n/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
collectgarbage()
collectgarbage('setpause', 110)
collectgarbage('setstepmul', 1000)

