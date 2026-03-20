#!/bin/bash
# Layout 1: デフォルト配置
# Chrome → M1、Mac本体は B1 にその他雑多なアプリ
#
# 使える aerospace コマンド:
#   aerospace list-windows --all           # 全ウィンドウ一覧
#   aerospace move-node-to-workspace <WS>  # ウィンドウを移動
#   aerospace focus --window-id <ID>       # 特定ウィンドウにフォーカス
#   aerospace workspace <WS>              # ワークスペース切り替え
#   aerospace layout tiles horizontal     # レイアウト変更

move_app_to_workspace() {
  local app_id="$1"
  local workspace="$2"
  aerospace list-windows --all --format '%{window-id} %{app-bundle-id}' \
    | grep -F "$app_id" \
    | while read -r wid _; do
        aerospace move-node-to-workspace --window-id "$wid" "$workspace"
      done
}

# Main Monitor
move_app_to_workspace 'com.google.Chrome'       'M1'
move_app_to_workspace 'company.thebrowser.dia'   'M2'
move_app_to_workspace 'com.github.wez.wezterm'   'M3'

# Sub Monitor
move_app_to_workspace 'notion.id'                'S1'
move_app_to_workspace 'com.microsoft.VSCode'     'S2'

# Mac Built-in: Claude Code Desktop, Activity Monitor → B1 にまとめる
move_app_to_workspace 'com.anthropic.claudefordesktop' 'B1'
move_app_to_workspace 'com.apple.ActivityMonitor'      'B1'

aerospace workspace M1
