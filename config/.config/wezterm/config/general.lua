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

  -- Left Option を Alt として送信（Alt+H/J/K/L の smart-splits 統合に必要）
  send_composed_key_when_left_alt_is_pressed = false,

  -- 設定ファイルの自動リロード
  automatically_reload_config = true,

  -- ウィンドウ終了時に確認ダイアログを表示
  window_close_confirmation = "AlwaysPrompt",

  -- カラースキーム
  color_scheme = "Tokyo Night Moon",
  colors = {
    tab_bar = {
      inactive_tab_edge = "none",
    },
    split = "#c0c8e0",

    -- QuickSelect 配色 (Tokyo Night Moon)
    quick_select_label_bg = { Color = "#ff966c" },  -- オレンジ: ヒントラベル背景
    quick_select_label_fg = { Color = "#1e2030" },  -- 暗色: ヒントラベル文字
    quick_select_match_bg = { Color = "#3b4261" },  -- 控えめ: マッチ箇所の背景
    quick_select_match_fg = { Color = "#c8d3f5" },  -- 明るい: マッチ箇所の文字
  },

  -- 非アクティブペインを暗くしてアクティブペインを際立たせる
  inactive_pane_hsb = {
    saturation = 0.8,
    brightness = 0.5,
  },

  -- スクロールバック行数
  scrollback_lines = 10000,

  -- QuickSelect カスタムパターン
  quick_select_patterns = {
    -- UUID
    "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
    -- IPv4 アドレス
    "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}",
    -- Docker コンテナ/イメージ ID (12桁 hex)
    "[0-9a-f]{12,64}",
    -- npm パッケージ名 (@scope/package)
    "@[a-zA-Z0-9-]+/[a-zA-Z0-9._-]+",
  },
}
