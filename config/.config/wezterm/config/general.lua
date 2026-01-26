-- 基本設定
return {
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
  },

  -- スクロールバック行数
  scrollback_lines = 10000,
}
