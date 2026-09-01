#!/bin/bash
# ワークスペース切替時に、オーバーレイ系アプリのウィンドウを追従させる
#
# 背景:
#   AeroSpace には sticky window（全ワークスペース表示）が無い（GitHub Issue #2、未実装）。
#   `layout floating` はタイリングエンジンから外すだけで、ワークスペースエンジンからは
#   外れないため、非アクティブワークスペースのウィンドウは画面隅へ退避されて見えなくなる。
#   Aqua Voice の音声入力オーバーレイがこれに巻き込まれる（2026-03 の導入見送り理由）。
#
# 対策:
#   exec-on-workspace-change から呼び、対象アプリのウィンドウを常に
#   フォーカス中のワークスペースへ引き寄せる。
#   `--fail-if-noop` で「既にそのワークスペースにいる」場合は何もしないため、
#   余計な移動＝点滅を避けられる（2026-03 に自前 debounce で失敗した箇所）。

set -u

# 追従させるアプリの bundle ID
FOLLOW_APP_IDS=(
  'com.electron.aqua-voice'
)

target="${AEROSPACE_FOCUSED_WORKSPACE:-}"
[[ -z "$target" ]] && exit 0

windows=$(aerospace list-windows --all --format '%{window-id}|%{app-bundle-id}' 2>/dev/null) || exit 0

for app_id in "${FOLLOW_APP_IDS[@]}"; do
  while IFS='|' read -r wid bid; do
    [[ "$bid" == "$app_id" ]] || continue
    # --fail-if-noop: 既に target にいるなら非ゼロ終了して何もしない
    aerospace move-node-to-workspace --window-id "$wid" --fail-if-noop "$target" 2>/dev/null
  done <<<"$windows"
done

exit 0
