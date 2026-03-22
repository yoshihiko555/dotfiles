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
  font = wezterm.font("UDEV Gothic 35NFLG", { weight = "Bold" }),
  font_size = 14,
}

-- イベントハンドラ
-- 起動時にメインモニターで3ペイン分割＋最大化
wezterm.on("gui-startup", function(cmd)
  -- 外部から引数付きで起動された場合はそちらを優先
  local spawn = cmd or {}
  local has_args = cmd and cmd.args

  if not has_args then
    -- tmux の default セッションに接続（なければ作成）
    spawn.args = { '/bin/zsh', '-lic', 'tmux new-session -A -s default "baton; exec $SHELL"' }
  end

  spawn.cwd = spawn.cwd or wezterm.home_dir
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
end)

return config
