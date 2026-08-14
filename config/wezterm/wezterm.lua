local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- 通知設定の初期化
local notification = require("config/notification")
notification.setup()

-- TabBarState 安定化（ちらつき防止）
-- enable_tab_bar=false でも WezTerm は毎サイクル TabBarState を再計算し、
-- 前回と異なると window.invalidate() が発火して画面がちらつく。
-- TabBarState は left_status, right_status, tab titles を含むため、
-- 全てのハンドラで固定値を返して安定させる。
wezterm.on("update-status", function(window)
  window:set_left_status("")
  window:set_right_status("")
end)
wezterm.on("format-tab-title", function(tab)
  return { { Text = " " .. tab.tab_index + 1 .. " " } }
end)

-- 外部設定ファイルをマージ
function merge_config(config, new_config)
  for k, v in pairs(new_config) do
    config[k] = v
  end
end

local window = require("config/window")
local keybinds = require("config/keybinds")
local font = require("config/font")
local general = require("config/general")
merge_config(config, general)
merge_config(config, window)
merge_config(config, keybinds)
merge_config(config, font)
merge_config(config, notification.config)

return config
