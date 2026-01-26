local wezterm = require("wezterm")

local M = {}

-- 通知設定
-- CodexはOSC通知ではなくosascriptを直接使うため、WezTermのOSC通知は無効化
-- （重複通知を防ぐ）
M.config = {
  notification_handling = "NeverShow",

  -- WezTerm内蔵のベル音を無効化（afplayで代替するため）
  audible_bell = "Disabled",
}

-- 通知音の設定
local notification_sound = "/System/Library/Sounds/Purr.aiff"
local notification_min_interval_sec = 1
local last_notification_ts = 0

-- 音声を再生する共通関数
local function play_notification_sound()
  local now = os.time()
  if now - last_notification_ts < notification_min_interval_sec then
    return
  end
  last_notification_ts = now
  wezterm.background_child_process({ "afplay", notification_sound })
end

-- イベントハンドラを登録
function M.setup()
  -- ベル発生時に音声を再生
  wezterm.on("bell", function(window, pane)
    play_notification_sound()
  end)
end

return M
