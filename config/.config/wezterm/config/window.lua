local wezterm = require("wezterm")
local config = {}
local mux = wezterm.mux

-- ウィンドウ設定
config.window_decorations = "RESIZE"
config.adjust_window_size_when_changing_font_size = false
config.window_background_opacity = 0.7
config.macos_window_background_blur = 20

-- 背景画像設定
config.background = {
  {
    source = {
      File = wezterm.home_dir .. "/.config/wezterm/background.jpg"
    },
    hsb = {
      brightness = 0.2,
    }
  }
}

-- タイトルバーを透明化
config.window_frame = {
  inactive_titlebar_bg = "none",
  active_titlebar_bg = "none",
}

-- イベントハンドラ
-- 起動時にメインモニターで3ペイン分割＋最大化
wezterm.on("gui-startup", function(cmd)
    -- cmd(SpawnCommand) を尊重して初期ウィンドウを作る
    -- これで `wezterm start --cwd ...` の cwd/args が反映される
    local spawn = cmd or {}

    -- 起動引数で渡された cwd をベースにする（無ければ home）
    local base_cwd = spawn.cwd or wezterm.home_dir
    spawn.cwd = base_cwd
    local tab, pane, window = mux.spawn_window(spawn)
    
    -- AppleScript でウィンドウをサブモニターに移動
    wezterm.run_child_process({
      "osascript", "-e", [[
        tell application "System Events"
          tell process "WezTerm"
            set position of window 1 to {0, 0}
          end tell
        end tell
      ]]
    })

    window:gui_window():maximize()
    wezterm.sleep_ms(200)

    -- パターン1: 左1 + 右上下2
    -- ┌──────┬──────┐
    -- │      │  2   │
    -- │  1   ├──────┤
    -- │      │  3   │
    -- └──────┴──────┘

    -- 右側に縦分割（50%）
    local right_pane = pane:split({ direction = "Right", size = 0.5, cwd = base_cwd })
    right_pane:split({ direction = "Bottom", size = 0.5, cwd = base_cwd })
    -- 左ペインにフォーカス
    pane:activate()
end)

return config
