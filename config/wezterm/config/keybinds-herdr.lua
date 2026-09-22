local wezterm = require 'wezterm'
local act = wezterm.action

-- herdr 用キーバインド層
--
-- config/keybinds.lua（tmux 版）を土台にして、herdr 側で送出先が変わる
-- キーだけを除外し、herdr 用の送出に差し替える。tmux 版との差分のみを
-- 管理し、コピーモード・検索モード等の key_tables はそのまま流用する。

local keybinds = require("config/keybinds")

-- 本番 (tmux 版) から除外するキー（herdr 側で送出先を変える/未実装のため）:
--   Cmd+D          … 本番は Ctrl+Q,r (resize_mode) だが herdr の prefix+r は
--                     リサイズモードなので Ctrl+Q,v (split_vertical) に差し替え
--   Cmd+Shift+D    … 本番は Ctrl+Q,d だが herdr の prefix+d は未割当なので
--                     Ctrl+Q,- (split_horizontal) に差し替え
--   Cmd+1〜Cmd+8   … 本番は Alt+1..8 を送出。herdr は alt+1..9 なので
--                     9 まで拡張して下で作り直す
--   Cmd+Shift+W    … 本番は Ctrl+Q,Shift+X (確認付き終了) だが、herdr 側は
--                     prefix+alt+x に herdr-kill-workspace-checked
--                     (実行中プロセスがあれば確認するワークスペース終了) を
--                     割り当てているため、ここでも Ctrl+Q の後に Alt+X を
--                     送るよう差し替える
--   Shift+Enter    … 本番は SendString("\n") を tmux 側がプロセス判定で
--                     takt 用の信号に変換していた。herdr にその変換が無いため
--                     素の \n が届き、takt が壊れる。WezTerm の既定の挙動
--                     （SendString("\n") ではなく Enter キーそのものの送出）に任せる。
local excluded_keys = {
  ['d|SUPER'] = true,
  ['d|SUPER|SHIFT'] = true,
  ['w|SUPER|SHIFT'] = true,
  ['Enter|SHIFT'] = true,
  ['1|SUPER'] = true,
  ['2|SUPER'] = true,
  ['3|SUPER'] = true,
  ['4|SUPER'] = true,
  ['5|SUPER'] = true,
  ['6|SUPER'] = true,
  ['7|SUPER'] = true,
  ['8|SUPER'] = true,
}

local herdr_keys = {}
for _, k in ipairs(keybinds.keys) do
  local id = tostring(k.key) .. '|' .. tostring(k.mods)
  if not excluded_keys[id] then
    table.insert(herdr_keys, k)
  end
end

-- Cmd+D → Ctrl+Q,v (split_vertical)
table.insert(herdr_keys, {
  key = 'd', mods = 'SUPER', action = act.Multiple{
    act.SendKey{ key = 'q', mods = 'CTRL' },
    act.SendKey{ key = 'v' },
  }
})
-- Cmd+Shift+D → Ctrl+Q,- (split_horizontal)
table.insert(herdr_keys, {
  key = 'd', mods = 'SUPER|SHIFT', action = act.Multiple{
    act.SendKey{ key = 'q', mods = 'CTRL' },
    act.SendKey{ key = '-' },
  }
})
-- Cmd+Shift+W → Ctrl+Q, Alt+X (herdr-kill-workspace-checked: prefix+alt+x)
table.insert(herdr_keys, {
  key = 'w', mods = 'SUPER|SHIFT', action = act.Multiple{
    act.SendKey{ key = 'q', mods = 'CTRL' },
    act.SendKey{ key = 'x', mods = 'ALT' },
  }
})
-- Cmd+1〜Cmd+9 → Alt+1..9 送出（herdr の switch_tab = "alt+1..9" に対応）
for i = 1, 9 do
  local digit = tostring(i)
  table.insert(herdr_keys, {
    key = digit, mods = 'SUPER', action = act.SendKey{ key = digit, mods = 'ALT' },
  })
end
-- Cmd+S → Ctrl+Q, d を送出（herdr の toggle_sidebar = "prefix+d"）
table.insert(herdr_keys, {
  key = 's', mods = 'SUPER', action = act.Multiple{
    act.SendKey{ key = 'q', mods = 'CTRL' },
    act.SendKey{ key = 'd' },
  }
})

return {
  disable_default_key_bindings = true,
  keys = herdr_keys,
  key_tables = keybinds.key_tables,
}
