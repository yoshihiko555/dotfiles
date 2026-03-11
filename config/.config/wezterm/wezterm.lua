local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- 通知設定の初期化
local notification = require("config/notification")
notification.setup()

-- タブ設定の初期化
local tab = require("config/tab")
tab.setup()

-- ステータスバー設定の初期化
local statusbar = require("config/statusbar")
statusbar.setup()

-- コマンドパレット拡張の初期化
local command_palette = require("config/command_palette")
command_palette.setup()

-- Alfred 外部ワークスペース切替の初期化
local actions = require("config/actions")
actions.setup_alfred_watcher()

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
merge_config(config, tab.config)
merge_config(config, window)
merge_config(config, keybinds)
merge_config(config, font)
merge_config(config, notification.config)

return config
