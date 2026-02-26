local wezterm = require("wezterm")
local act = wezterm.action

-- 基本設定
return {
  -- URLをCtrl+Clickでのみ開く（誤クリック防止）
  mouse_bindings = {
    -- 通常クリックでURLを開かないようにする
    {
      event = { Up = { streak = 1, button = "Left" } },
      mods = "NONE",
      action = act.CompleteSelection("ClipboardAndPrimarySelection"),
    },
    -- Cmd+ClickでURLを開く (macOS)
    {
      event = { Up = { streak = 1, button = "Left" } },
      mods = "SUPER",
      action = act.OpenLinkAtMouseCursor,
    },
  },

  -- 設定ファイルの自動リロード
  automatically_reload_config = true,

  -- ウィンドウ終了時に確認ダイアログを表示
  window_close_confirmation = "AlwaysPrompt",

  -- タブバー設定
  hide_tab_bar_if_only_one_tab = true,
  show_new_tab_button_in_tab_bar = false,
  show_close_tab_button_in_tabs = false,

  -- カラースキーム
  color_scheme = "Tokyo Night Moon",
  colors = {
    tab_bar = {
      inactive_tab_edge = "none",
    },
    split = "#c0c8e0",
  },

  -- 非アクティブペインを暗くしてアクティブペインを際立たせる
  inactive_pane_hsb = {
    saturation = 0.8,
    brightness = 0.6,
  },

  -- スクロールバック行数
  scrollback_lines = 10000,
}
