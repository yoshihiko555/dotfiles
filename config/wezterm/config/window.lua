local wezterm = require("wezterm")
local config = {}
local mux = wezterm.mux

-- ウィンドウの見た目設定
local appearance = require("config/window-appearance")
for k, v in pairs(appearance) do
  config[k] = v
end

-- 起動時に tmux を開いて最大化
wezterm.on("gui-startup", function(cmd)
  -- 外部から引数付きで起動された場合はそちらを優先
  local spawn = cmd or {}
  local has_args = cmd and cmd.args

  if not has_args then
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
