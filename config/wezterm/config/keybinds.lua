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
    -- 文字選択
    ---------------------------------------------------------------------------
    { key = 'u', mods = 'SHIFT|CTRL', action = act.CharSelect{ copy_on_select = true, copy_to = 'ClipboardAndPrimarySelection' } },

    ---------------------------------------------------------------------------
    -- フォントサイズ
    ---------------------------------------------------------------------------
    { key = '=', mods = 'SUPER', action = act.IncreaseFontSize },
    { key = '-', mods = 'SUPER', action = act.DecreaseFontSize },
    { key = '0', mods = 'SUPER', action = act.ResetFontSize },

    ---------------------------------------------------------------------------
    -- tmux 操作ショートカット (Cmd → tmux Prefix(Ctrl+Q) に変換)
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
    -- セッション閉じ (Cmd+Shift+W → Prefix+X)
    { key = 'w', mods = 'SUPER|SHIFT', action = act.Multiple{
      act.SendKey{ key = 'q', mods = 'CTRL' },
      act.SendKey{ key = 'X', mods = 'SHIFT' },
    } },

    ---------------------------------------------------------------------------
    -- ウィンドウ・アプリケーション
    ---------------------------------------------------------------------------
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
}
