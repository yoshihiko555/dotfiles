local wezterm = require("wezterm")
local config = {}

-- フォント設定
config.font = wezterm.font("UDEV Gothic 35NFLG", { weight = "Bold" })
config.font_size = 15
config.use_ime = true
config.line_height = 1.2

return config
