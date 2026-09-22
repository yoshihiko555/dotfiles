local wezterm = require("wezterm")
local config = {}
local mux = wezterm.mux

-- ウィンドウの見た目設定（tmux 版と共通のため切り出し。config/window-appearance.lua 参照）
local appearance = require("config/window-appearance")
for k, v in pairs(appearance) do
  config[k] = v
end

-- イベントハンドラ
-- 起動時にメインモニターで herdr を起動＋最大化。
-- AppleScript でのウィンドウ移動・最大化、引数付き起動時の優先処理は
-- config/window.lua（tmux 版）と同じ。
wezterm.on("gui-startup", function(cmd)
  -- 外部から引数付きで起動された場合はそちらを優先
  local spawn = cmd or {}
  local has_args = cmd and cmd.args

  if not has_args then
    -- herdr を起動する。
    -- tmux 版 (config/window.lua) が `tmux` をフルパスではなく PATH 解決に
    -- 任せているのと同じ理由で、herdr も絶対パス (/opt/homebrew/bin/herdr)
    -- 固定にせずログイン+対話シェル (`zsh -lic`) 経由で PATH 解決に任せる。
    -- 理由:
    --   - herdr 配下で起動するエージェントペイン（claude/codex 等）は
    --     .zshrc/.zprofile で設定される PATH（mise, Homebrew 等）が必要で、
    --     どのみちログインシェルを経由させる必要がある。herdr 自身だけ
    --     絶対パスにしても、子プロセス側の PATH 問題は解決しない。
    --   - herdr 自身の config.toml 内の popup コマンドもすべて `zsh -ic` 経由
    --     （例: `zsh -ic 'lazygit'`）で、同じ PATH 解決に依存する設計になっている。
    --   - GUI から起動した WezTerm プロセスの環境変数には Homebrew の PATH
    --     (`/opt/homebrew/bin`) が乗っていない可能性があるが、`.zshenv`
    --     （zsh がログイン/非ログイン・対話/非対話を問わず必ず読む）に
    --     `eval "$(/opt/homebrew/bin/brew shellenv)"` があるため、`zsh` を
    --     経由するだけで PATH に追加される（`env -i ... zsh -lic
    --     'command -v herdr'` で実機確認済み）。
    spawn.args = { '/bin/zsh', '-lic', 'herdr' }
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
