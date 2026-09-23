local wezterm = require("wezterm")
local config = {}
local mux = wezterm.mux

-- ウィンドウの見た目設定
local appearance = require("config/window-appearance")
for k, v in pairs(appearance) do
  config[k] = v
end

-- 起動時に tmux の default セッション（baton 常駐）を開く。配置は AeroSpace に任せる
wezterm.on("gui-startup", function(cmd)
  -- 外部から引数付きで起動された場合はそちらを優先
  local spawn = cmd or {}
  local has_args = cmd and cmd.args

  if not has_args then
    spawn.args = { '/bin/zsh', '-lic', 'tmux new-session -A -s default "baton; exec $SHELL"' }
  end

  spawn.cwd = spawn.cwd or wezterm.home_dir
  mux.spawn_window(spawn)
end)

return config
