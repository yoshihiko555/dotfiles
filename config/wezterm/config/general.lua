-- 基本設定
return {
  -- Left Option を Alt として送信（Alt+H/J/K/L の smart-splits 統合に必要）
  send_composed_key_when_left_alt_is_pressed = false,

  -- ウィンドウ終了時に確認ダイアログを表示
  window_close_confirmation = "AlwaysPrompt",

  -- カラースキーム
  color_scheme = "Tokyo Night Moon",

  -- タブバー完全無効化（tmux がウィンドウ/タブを管理）
  enable_tab_bar = false,

  -- ステータス更新間隔を最大化（タブバー無効のため不要、デフォルト1000ms）
  status_update_interval = 86400000,
}
