#!/bin/bash
# Layout 2: 開発モード
# Chrome → B1 に移動、B2 に Claude Code Desktop + Activity Monitor をタイリング
#
# デフォルトとの違い:
#   - Chrome が M1 → B1 に移動（Mac本体でブラウザ参照）
#   - B2 に開発系ツールをタイリング配置

move_app_to_workspace() {
  local app_id="$1"
  local workspace="$2"
  aerospace list-windows --all --format '%{window-id} %{app-bundle-id}' \
    | grep -F "$app_id" \
    | while read -r wid _; do
        aerospace move-node-to-workspace --window-id "$wid" "$workspace"
      done
}

# Main Monitor（Chrome なし）
move_app_to_workspace 'company.thebrowser.dia'   'M2'
move_app_to_workspace 'com.github.wez.wezterm'   'M3'

# Sub Monitor
move_app_to_workspace 'notion.id'                'S1'
move_app_to_workspace 'com.microsoft.VSCode'     'S2'

# Mac Built-in: B1 に Chrome、B2 に開発ツール群（タイリング）
move_app_to_workspace 'com.google.Chrome'              'B1'
move_app_to_workspace 'com.anthropic.claudefordesktop' 'B2'
move_app_to_workspace 'com.apple.ActivityMonitor'      'B2'

aerospace workspace B2
