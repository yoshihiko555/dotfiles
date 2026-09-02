#!/bin/bash
# Layout 2: 開発モード
# デフォルトとの違いはメインモニターの使い方だけ:
#   - Chrome を M1 から M4 へ退避し、M1 に Zed / VS Code（エディタ系）を持ってくる
#   - TablePlus はデフォルトどおり S2 に置き、サブ DELL で参照する
#   - メイン DELL で「エディタ・ターミナル」を並べて見られる状態にする
# B 系（コミュニケーション）はデフォルトと同じ。

move_app_to_workspace() {
  local app_id="$1"
  local workspace="$2"
  aerospace list-windows --all --format '%{window-id} %{app-bundle-id}' \
    | grep -F "$app_id" \
    | while read -r wid _; do
        aerospace move-node-to-workspace --window-id "$wid" "$workspace"
      done
}

# Main Monitor: 開発向けに入れ替え
move_app_to_workspace 'dev.zed.Zed'             'M1'
move_app_to_workspace 'com.microsoft.VSCode'    'M1'
move_app_to_workspace 'company.thebrowser.dia'  'M2'
move_app_to_workspace 'com.github.wez.wezterm'  'M3'
move_app_to_workspace 'com.google.Chrome'       'M4'

# Sub Monitor
move_app_to_workspace 'notion.id'               'S1'
move_app_to_workspace 'com.tinyapp.TablePlus'   'S2'
move_app_to_workspace 'com.apple.systempreferences' 'S3'
move_app_to_workspace 'com.apple.ActivityMonitor'   'S3'
move_app_to_workspace 'com.coteditor.CotEditor'     'S3'

# Mac Built-in（デフォルトと同じ）
move_app_to_workspace 'com.tinyspeck.slackmacgap' 'B1'
move_app_to_workspace 'com.hnc.Discord'           'B1'
move_app_to_workspace 'com.microsoft.teams2'      'B1'
move_app_to_workspace 'com.apple.mail'            'B2'
move_app_to_workspace 'com.cron.electron'         'B2'

aerospace workspace M3
