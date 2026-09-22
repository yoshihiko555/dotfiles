local wezterm = require("wezterm")

-- ウィンドウの見た目設定（tmux 版・herdr 版で共通）
--
-- config/window.lua（既定・tmux 版）と config/window-herdr.lua（herdr 版）は
-- gui-startup ハンドラ（起動時にどちらのマルチプレクサを立ち上げるか）だけが
-- 異なり、背景・透過・装飾・タイトルバーの見た目は同一にしたい。二重管理を
-- 避けるため見た目部分だけをここに切り出し、両ファイルから require する。
local M = {}

-- ウィンドウ設定
M.window_decorations = "RESIZE"
M.adjust_window_size_when_changing_font_size = false
M.window_background_opacity = 0.7
M.macos_window_background_blur = 20

-- 背景画像設定
M.background = {
  {
    source = {
      File = wezterm.home_dir .. "/.config/wezterm/background.jpg"
    },
    hsb = {
      brightness = 0.2,
    }
  }
}

-- タイトルバーを透明化
M.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
  font = wezterm.font("UDEV Gothic 35NFLG", { weight = "Bold" }),
  font_size = 14,
}

return M
