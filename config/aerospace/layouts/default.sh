#!/bin/bash
# Layout 1: デフォルト配置
# aerospace.toml の on-window-detected と同じ対応表を、既に開いているウィンドウへ
# 一括適用する。ルール追加前から開いていたウィンドウを揃え直す用途。
#
# 使える aerospace コマンド:
#   aerospace list-windows --all           # 全ウィンドウ一覧
#   aerospace move-node-to-workspace <WS>  # ウィンドウを移動
#   aerospace focus --window-id <ID>       # 特定ウィンドウにフォーカス
#   aerospace workspace <WS>               # ワークスペース切り替え
#   aerospace layout tiles horizontal      # レイアウト変更

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
move_app_to_workspace 'company.thebrowser.dia'  'M2'
move_app_to_workspace 'com.github.wez.wezterm'  'M3'
# M4 は空き枠（Hermes 画面共有等）。ルールを持たない。

# Sub Monitor
move_app_to_workspace 'notion.id'               'S1'
move_app_to_workspace 'dev.zed.Zed'             'S2'
move_app_to_workspace 'com.microsoft.VSCode'    'S2'
move_app_to_workspace 'com.tinyapp.TablePlus'   'S2'

# Mac Built-in
move_app_to_workspace 'com.tinyspeck.slackmacgap' 'B1'
move_app_to_workspace 'com.hnc.Discord'           'B1'
move_app_to_workspace 'com.microsoft.teams2'      'B1'
move_app_to_workspace 'com.apple.mail'            'B2'
move_app_to_workspace 'com.cron.electron'         'B2'
move_app_to_workspace 'com.apple.systempreferences' 'B3'
move_app_to_workspace 'com.apple.ActivityMonitor'   'B3'
move_app_to_workspace 'com.coteditor.CotEditor'     'B3'

aerospace workspace M1
