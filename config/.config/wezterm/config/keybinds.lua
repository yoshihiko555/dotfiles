local wezterm = require 'wezterm'
local act = wezterm.action

-- tmux-first 環境: WezTerm は GUI レンダラーに限定
-- タブ/ペイン/セッション管理は tmux 側で行う
return {
  -- デフォルトのキーバインド無効化
  disable_default_key_bindings = true,
  keys = {
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
    { key = 'k', mods = 'SUPER', action = act.ClearScrollback 'ScrollbackAndViewport' },

    ---------------------------------------------------------------------------
    -- tmux 操作ショートカット (Cmd → tmux Prefix(Ctrl+T) に変換)
    ---------------------------------------------------------------------------
    -- ウィンドウ切替 (Cmd+1-8 → Alt+1-8)
    { key = '1', mods = 'SUPER', action = act.SendKey{ key = '1', mods = 'ALT' } },
    { key = '2', mods = 'SUPER', action = act.SendKey{ key = '2', mods = 'ALT' } },
    { key = '3', mods = 'SUPER', action = act.SendKey{ key = '3', mods = 'ALT' } },
    { key = '4', mods = 'SUPER', action = act.SendKey{ key = '4', mods = 'ALT' } },
    { key = '5', mods = 'SUPER', action = act.SendKey{ key = '5', mods = 'ALT' } },
    { key = '6', mods = 'SUPER', action = act.SendKey{ key = '6', mods = 'ALT' } },
    { key = '7', mods = 'SUPER', action = act.SendKey{ key = '7', mods = 'ALT' } },
    { key = '8', mods = 'SUPER', action = act.SendKey{ key = '8', mods = 'ALT' } },
    -- 新規ウィンドウ (Cmd+T → Prefix+c)
    { key = 't', mods = 'SUPER', action = act.Multiple{
      act.SendKey{ key = 'q', mods = 'CTRL' },
      act.SendKey{ key = 'c' },
    } },
    -- ペイン分割 (Cmd+D → Prefix+r, Cmd+Shift+D → Prefix+d)
    { key = 'd', mods = 'SUPER', action = act.Multiple{
      act.SendKey{ key = 'q', mods = 'CTRL' },
      act.SendKey{ key = 'r' },
    } },
    { key = 'd', mods = 'SUPER|SHIFT', action = act.Multiple{
      act.SendKey{ key = 'q', mods = 'CTRL' },
      act.SendKey{ key = 'd' },
    } },
    -- ペイン閉じ (Cmd+W → Prefix+x)
    { key = 'w', mods = 'SUPER', action = act.Multiple{
      act.SendKey{ key = 'q', mods = 'CTRL' },
      act.SendKey{ key = 'x' },
    } },

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
    { key = 'p', mods = 'SUPER|SHIFT', action = act.ActivateCommandPalette },
    { key = 'l', mods = 'SHIFT|CTRL', action = act.ShowDebugOverlay },
  },

  ---------------------------------------------------------------------------
  -- Key Tables
  ---------------------------------------------------------------------------
  key_tables = {
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
