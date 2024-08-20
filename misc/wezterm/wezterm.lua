local wezterm = require('wezterm')
local config = {}

config.default_prog = { "bash" }

config.warn_about_missing_glyphs = false
config.font = wezterm.font_with_fallback({
	"Iosevka Nerd Font Mono",
	"Noto Color Emoji",
})
config.font_size = 15.0
config.color_scheme = 'GruvboxDark'
config.enable_tab_bar = false
config.enable_scroll_bar = false
PADDING = "0.3%"
config.window_padding = {
	left = PADDING,
	right = PADDING,
	top = PADDING,
	bottom = PADDING,
}
config.window_close_confirmation = 'NeverPrompt'
config.enable_wayland = false


-- fck audible bell, all my homies hate audible bell...
config.audible_bell = "Disabled"
config.colors = { visual_bell = '#202020', }
config.visual_bell = {
	fade_in_function = 'EaseIn',
	fade_in_duration_ms = 75,
	fade_out_function = 'EaseOut',
	fade_out_duration_ms = 75,
}


config.keys = {
	{
		key = 'v',
		mods = 'ALT',
		action = wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
	},
	{
		key = 's',
		mods = 'ALT',
		action = wezterm.action.SplitVertical({ domain = 'CurrentPaneDomain' }),
	},
	{
		key = 'h',
		mods = 'ALT',
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = 'l',
		mods = 'ALT',
		action = wezterm.action.ActivatePaneDirection("Right"),
	},
	{
		key = 'k',
		mods = 'ALT',
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		key = 'j',
		mods = 'ALT',
		action = wezterm.action.ActivatePaneDirection("Down"),
	},
	{
		key = 'x',
		mods = 'ALT',
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	{
		key = 't',
		mods = 'ALT',
		action = wezterm.action.SpawnTab('CurrentPaneDomain'),
	},
	{
		key = '6',
		mods = 'ALT',
		action = wezterm.action.ActivateLastTab,
	},
	{
		key = 'q',
		mods = 'ALT',
		action = wezterm.action.CloseCurrentTab({ confirm = true }),
	},
	{
		key = 'Tab',
		mods = 'ALT',
		action = wezterm.action.ActivateTabRelative(1),
	},
	{
		key = 'Tab',
		mods = 'ALT|SHIFT',
		action = wezterm.action.ActivateTabRelative(-1),
	},
}

return config
