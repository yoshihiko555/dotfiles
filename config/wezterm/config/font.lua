local wezterm = require("wezterm")
local config = {}

-- フォント設定
-- 第1候補以降は fallback。WezTerm 組み込みの fallback は
-- JetBrains Mono / Noto Color Emoji / Symbols Nerd Font Mono のみで
-- macOS のシステムフォントは自動では使われないため、明示的に追加する。
config.font = wezterm.font_with_fallback({
  { family = "UDEV Gothic 35NFLG", weight = "Bold" },
  "Hiragino Sans",        -- 日本語（UDEV Gothic に無い漢字・記号）
  "PingFang SC",          -- 簡体字
  "Apple SD Gothic Neo",  -- ハングル
  "Apple Symbols",        -- 数学記号・その他シンボル
  "Apple Color Emoji",    -- 絵文字
})
config.font_size = 15
config.use_ime = true
config.line_height = 1.2

return config
