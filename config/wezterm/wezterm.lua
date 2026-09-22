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

-- tmux / herdr 切り替え -------------------------------------------------
-- リポジトリ外のファイル ~/.config/use-herdr の有無だけで切り替える。
--   ファイルが無い → 既定: tmux + baton（今までどおり）
--   ファイルがある → herdr
-- 中身は見ない。存在そのものが意思表示なので、`touch` で切り替え `rm` で戻す。
-- リポジトリ側には一切書き込まないので、git status を汚さずに切り替えられる。
local function use_herdr()
  local path = wezterm.home_dir .. "/.config/use-herdr"
  local file = io.open(path, "r")
  if not file then
    return false
  end
  file:close()
  return true
end

local window, keybinds
if use_herdr() then
  window = require("config/window-herdr")
  keybinds = require("config/keybinds-herdr")
else
  window = require("config/window")
  keybinds = require("config/keybinds")
end

local font = require("config/font")
local general = require("config/general")
merge_config(config, general)
merge_config(config, window)
merge_config(config, keybinds)
merge_config(config, font)
merge_config(config, notification.config)

return config
