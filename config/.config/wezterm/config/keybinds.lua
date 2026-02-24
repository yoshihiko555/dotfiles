local wezterm = require 'wezterm'
local act = wezterm.action
local actions = require 'config/actions'

return {
  -- デフォルトのキーバインド無効化
  disable_default_key_bindings = true,
  -- リーダーキー設定
  leader = { key = "q", mods = "CTRL", timeout_milliseconds = 2000 },
  keys = {
    ---------------------------------------------------------------------------
    -- タブ操作
    ---------------------------------------------------------------------------
    { key = 't', mods = 'SUPER', action = actions.spawn_tab_with_3_panes },
    { key = 'w', mods = 'SUPER', action = act.CloseCurrentPane{ confirm = true } },
    { key = 'w', mods = 'SUPER|SHIFT', action = act.CloseCurrentTab{ confirm = true } },
    { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
    { key = 'Tab', mods = 'SHIFT|CTRL', action = act.ActivateTabRelative(-1) },
    { key = '{', mods = 'SUPER', action = act.ActivateTabRelative(-1) },
    { key = '}', mods = 'SUPER', action = act.ActivateTabRelative(1) },
    -- タブ番号で直接移動 (Cmd + 1-9)
    { key = '1', mods = 'SUPER', action = act.ActivateTab(0) },
    { key = '2', mods = 'SUPER', action = act.ActivateTab(1) },
    { key = '3', mods = 'SUPER', action = act.ActivateTab(2) },
    { key = '4', mods = 'SUPER', action = act.ActivateTab(3) },
    { key = '5', mods = 'SUPER', action = act.ActivateTab(4) },
    { key = '6', mods = 'SUPER', action = act.ActivateTab(5) },
    { key = '7', mods = 'SUPER', action = act.ActivateTab(6) },
    { key = '8', mods = 'SUPER', action = act.ActivateTab(7) },
    { key = '9', mods = 'SUPER', action = act.ActivateTab(-1) },
    -- タブ移動
    { key = 'PageUp', mods = 'SHIFT|CTRL', action = act.MoveTabRelative(-1) },
    { key = 'PageDown', mods = 'SHIFT|CTRL', action = act.MoveTabRelative(1) },

    ---------------------------------------------------------------------------
    -- ペイン操作 (Cmd)
    ---------------------------------------------------------------------------
    { key = 'd', mods = 'SUPER', action = act.SplitHorizontal{ domain = 'CurrentPaneDomain' } },
    { key = 'd', mods = 'SUPER|SHIFT', action = act.SplitVertical{ domain = 'CurrentPaneDomain' } },
    { key = 'z', mods = 'CTRL', action = act.TogglePaneZoomState },
    -- 矢印キーでペイン移動・サイズ調整
    { key = 'LeftArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Left' },
    { key = 'RightArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Right' },
    { key = 'UpArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Up' },
    { key = 'DownArrow', mods = 'SHIFT|CTRL', action = act.ActivatePaneDirection 'Down' },
    { key = 'LeftArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize{ 'Left', 1 } },
    { key = 'RightArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize{ 'Right', 1 } },
    { key = 'UpArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize{ 'Up', 1 } },
    { key = 'DownArrow', mods = 'SHIFT|ALT|CTRL', action = act.AdjustPaneSize{ 'Down', 1 } },

    ---------------------------------------------------------------------------
    -- ペイン操作 (Leader: Ctrl+q)
    ---------------------------------------------------------------------------
    -- 8分割タブ
    { key = '8', mods = 'LEADER', action = actions.spawn_tab_with_8_panes },
    -- ワークスペース初期化（8ペインタブで pane 1 の cwd を基準に各ツール起動）
    { key = 'i', mods = 'LEADER', action = actions.init_workspace },
    -- 分割
    { key = 'd', mods = 'LEADER', action = act.SplitVertical{ domain = 'CurrentPaneDomain' } },
    { key = '/', mods = 'LEADER', action = act.SplitHorizontal{ domain = 'CurrentPaneDomain' } },
    -- 移動 (vim風・単発)
    { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
    { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
    { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
    { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },
    -- サイズ調整 (単発)
    { key = 'H', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize{ 'Left', 5 } },
    { key = 'J', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize{ 'Down', 5 } },
    { key = 'K', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize{ 'Up', 5 } },
    { key = 'L', mods = 'LEADER|SHIFT', action = act.AdjustPaneSize{ 'Right', 5 } },
    -- ペイン操作モード (連続操作)
    { key = 'p', mods = 'LEADER', action = act.ActivateKeyTable{ name = 'pane_mode', one_shot = false } },

    ---------------------------------------------------------------------------
    -- コピー・ペースト
    ---------------------------------------------------------------------------
    { key = 'c', mods = 'SUPER', action = act.CopyTo 'Clipboard' },
    { key = 'v', mods = 'SUPER', action = act.PasteFrom 'Clipboard' },
    { key = 'Copy', mods = 'NONE', action = act.CopyTo 'Clipboard' },
    { key = 'Paste', mods = 'NONE', action = act.PasteFrom 'Clipboard' },

    ---------------------------------------------------------------------------
    -- 検索・選択
    ---------------------------------------------------------------------------
    { key = 'f', mods = 'SUPER', action = act.Search 'CurrentSelectionOrEmptyString' },
    { key = 'x', mods = 'SHIFT|CTRL', action = act.ActivateCopyMode },
    { key = 'phys:Space', mods = 'SHIFT|CTRL', action = act.QuickSelect },
    { key = 'u', mods = 'SHIFT|CTRL', action = act.CharSelect{ copy_on_select = true, copy_to = 'ClipboardAndPrimarySelection' } },

    ---------------------------------------------------------------------------
    -- フォントサイズ
    ---------------------------------------------------------------------------
    { key = '=', mods = 'SUPER', action = act.IncreaseFontSize },
    { key = '-', mods = 'SUPER', action = act.DecreaseFontSize },
    { key = '0', mods = 'SUPER', action = act.ResetFontSize },

    ---------------------------------------------------------------------------
    -- スクロール
    ---------------------------------------------------------------------------
    { key = 'PageUp', mods = 'SHIFT', action = act.ScrollByPage(-1) },
    { key = 'PageDown', mods = 'SHIFT', action = act.ScrollByPage(1) },
    { key = 'k', mods = 'SUPER', action = actions.clear_scrollback_and_viewport },
    -- Ctrl+L: 画面クリア（スクロールバックに内容を保存）
    { key = 'l', mods = 'CTRL', action = actions.clear_screen_save_scrollback },

    ---------------------------------------------------------------------------
    -- ウィンドウ・アプリケーション
    ---------------------------------------------------------------------------
    { key = 'n', mods = 'SUPER', action = act.SpawnWindow },
    { key = 'Enter', mods = 'ALT', action = act.ToggleFullScreen },
    { key = 'h', mods = 'SUPER', action = act.HideApplication },
    { key = 'm', mods = 'SUPER', action = act.Hide },
    { key = 'q', mods = 'SUPER', action = act.QuitApplication },

    ---------------------------------------------------------------------------
    -- その他
    ---------------------------------------------------------------------------
    { key = 'Enter', mods = 'SHIFT', action = act.SendString '\n' },
    { key = 'r', mods = 'SUPER', action = act.ReloadConfiguration },
    { key = 'p', mods = 'SHIFT|CTRL', action = act.ActivateCommandPalette },
    { key = 'l', mods = 'SHIFT|CTRL', action = act.ShowDebugOverlay },
  },

  ---------------------------------------------------------------------------
  -- Key Tables
  ---------------------------------------------------------------------------
  key_tables = {
    -- ペイン操作モード (Leader + p で入る)
    pane_mode = {
      { key = 'h', mods = 'NONE', action = act.ActivatePaneDirection 'Left' },
      { key = 'j', mods = 'NONE', action = act.ActivatePaneDirection 'Down' },
      { key = 'k', mods = 'NONE', action = act.ActivatePaneDirection 'Up' },
      { key = 'l', mods = 'NONE', action = act.ActivatePaneDirection 'Right' },
      { key = 'H', mods = 'SHIFT', action = act.AdjustPaneSize{ 'Left', 5 } },
      { key = 'J', mods = 'SHIFT', action = act.AdjustPaneSize{ 'Down', 5 } },
      { key = 'K', mods = 'SHIFT', action = act.AdjustPaneSize{ 'Up', 5 } },
      { key = 'L', mods = 'SHIFT', action = act.AdjustPaneSize{ 'Right', 5 } },
      { key = 'd', mods = 'NONE', action = act.SplitVertical{ domain = 'CurrentPaneDomain' } },
      { key = '/', mods = 'NONE', action = act.SplitHorizontal{ domain = 'CurrentPaneDomain' } },
      { key = 'x', mods = 'NONE', action = act.CloseCurrentPane{ confirm = true } },
      { key = 'z', mods = 'NONE', action = act.TogglePaneZoomState },
      -- 数字キーでペイン直接移動
      { key = '1', mods = 'NONE', action = act.ActivatePaneByIndex(0) },
      { key = '2', mods = 'NONE', action = act.ActivatePaneByIndex(1) },
      { key = '3', mods = 'NONE', action = act.ActivatePaneByIndex(2) },
      { key = '4', mods = 'NONE', action = act.ActivatePaneByIndex(3) },
      { key = '5', mods = 'NONE', action = act.ActivatePaneByIndex(4) },
      { key = '6', mods = 'NONE', action = act.ActivatePaneByIndex(5) },
      { key = '7', mods = 'NONE', action = act.ActivatePaneByIndex(6) },
      { key = '8', mods = 'NONE', action = act.ActivatePaneByIndex(7) },
      { key = '9', mods = 'NONE', action = act.ActivatePaneByIndex(8) },
      { key = 'Escape', mods = 'NONE', action = act.PopKeyTable },
      { key = 'Enter', mods = 'NONE', action = act.PopKeyTable },
      { key = 'q', mods = 'NONE', action = act.PopKeyTable },
    },

    -- コピーモード (vim風)
    copy_mode = {
      -- 終了
      { key = 'Escape', mods = 'NONE', action = act.Multiple{ 'ScrollToBottom', { CopyMode = 'Close' } } },
      { key = 'q', mods = 'NONE', action = act.Multiple{ 'ScrollToBottom', { CopyMode = 'Close' } } },
      { key = 'c', mods = 'CTRL', action = act.Multiple{ 'ScrollToBottom', { CopyMode = 'Close' } } },
      -- 移動
      { key = 'h', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
      { key = 'j', mods = 'NONE', action = act.CopyMode 'MoveDown' },
      { key = 'k', mods = 'NONE', action = act.CopyMode 'MoveUp' },
      { key = 'l', mods = 'NONE', action = act.CopyMode 'MoveRight' },
      { key = 'w', mods = 'NONE', action = act.CopyMode 'MoveForwardWord' },
      { key = 'b', mods = 'NONE', action = act.CopyMode 'MoveBackwardWord' },
      { key = 'e', mods = 'NONE', action = act.CopyMode 'MoveForwardWordEnd' },
      { key = '0', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLine' },
      { key = '$', mods = 'NONE', action = act.CopyMode 'MoveToEndOfLineContent' },
      { key = '^', mods = 'NONE', action = act.CopyMode 'MoveToStartOfLineContent' },
      { key = 'g', mods = 'NONE', action = act.CopyMode 'MoveToScrollbackTop' },
      { key = 'G', mods = 'NONE', action = act.CopyMode 'MoveToScrollbackBottom' },
      { key = 'H', mods = 'NONE', action = act.CopyMode 'MoveToViewportTop' },
      { key = 'M', mods = 'NONE', action = act.CopyMode 'MoveToViewportMiddle' },
      { key = 'L', mods = 'NONE', action = act.CopyMode 'MoveToViewportBottom' },
      -- ページ移動
      { key = 'f', mods = 'CTRL', action = act.CopyMode 'PageDown' },
      { key = 'b', mods = 'CTRL', action = act.CopyMode 'PageUp' },
      { key = 'd', mods = 'CTRL', action = act.CopyMode{ MoveByPage = 0.5 } },
      { key = 'u', mods = 'CTRL', action = act.CopyMode{ MoveByPage = -0.5 } },
      -- ジャンプ
      { key = 'f', mods = 'NONE', action = act.CopyMode{ JumpForward = { prev_char = false } } },
      { key = 'F', mods = 'NONE', action = act.CopyMode{ JumpBackward = { prev_char = false } } },
      { key = 't', mods = 'NONE', action = act.CopyMode{ JumpForward = { prev_char = true } } },
      { key = 'T', mods = 'NONE', action = act.CopyMode{ JumpBackward = { prev_char = true } } },
      { key = ';', mods = 'NONE', action = act.CopyMode 'JumpAgain' },
      { key = ',', mods = 'NONE', action = act.CopyMode 'JumpReverse' },
      -- 選択
      { key = 'v', mods = 'NONE', action = act.CopyMode{ SetSelectionMode = 'Cell' } },
      { key = 'V', mods = 'NONE', action = act.CopyMode{ SetSelectionMode = 'Line' } },
      { key = 'v', mods = 'CTRL', action = act.CopyMode{ SetSelectionMode = 'Block' } },
      { key = 'o', mods = 'NONE', action = act.CopyMode 'MoveToSelectionOtherEnd' },
      { key = 'O', mods = 'NONE', action = act.CopyMode 'MoveToSelectionOtherEndHoriz' },
      -- コピー
      { key = 'y', mods = 'NONE', action = act.Multiple{ { CopyTo = 'ClipboardAndPrimarySelection' }, { Multiple = { 'ScrollToBottom', { CopyMode = 'Close' } } } } },
      -- 矢印キー
      { key = 'LeftArrow', mods = 'NONE', action = act.CopyMode 'MoveLeft' },
      { key = 'RightArrow', mods = 'NONE', action = act.CopyMode 'MoveRight' },
      { key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'MoveUp' },
      { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'MoveDown' },
      { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PageUp' },
      { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'PageDown' },
    },

    -- 検索モード
    search_mode = {
      { key = 'Enter', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
      { key = 'Escape', mods = 'NONE', action = act.CopyMode 'Close' },
      { key = 'n', mods = 'CTRL', action = act.CopyMode 'NextMatch' },
      { key = 'p', mods = 'CTRL', action = act.CopyMode 'PriorMatch' },
      { key = 'r', mods = 'CTRL', action = act.CopyMode 'CycleMatchType' },
      { key = 'u', mods = 'CTRL', action = act.CopyMode 'ClearPattern' },
      { key = 'UpArrow', mods = 'NONE', action = act.CopyMode 'PriorMatch' },
      { key = 'DownArrow', mods = 'NONE', action = act.CopyMode 'NextMatch' },
      { key = 'PageUp', mods = 'NONE', action = act.CopyMode 'PriorMatchPage' },
      { key = 'PageDown', mods = 'NONE', action = act.CopyMode 'NextMatchPage' },
    },
  },
}
