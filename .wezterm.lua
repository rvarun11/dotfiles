-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = "Catppuccin Mocha" -- or Macchiato, Frappe, Latte

-- Font
config.font = wezterm.font("MesloLGS Nerd Font Mono")

config.font_size = 14.0

config.enable_tab_bar = false

-- config.window_background_opacity = 0.9
-- config.macos_window_background_blur = 10

config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}

return config
