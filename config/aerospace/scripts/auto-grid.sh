#!/bin/bash
# 新規ウィンドウ検知時に、同じ WS のタイル型ウィンドウを最大 2×2 に整列する。
# アプリの種類は問わず、フローティングと 5 枚以上は変更しない。
# フォーカスを動かさず、コールバックが渡す window-id を基準に操作する。

set -euo pipefail

AEROSPACE=${AEROSPACE_BIN:-/opt/homebrew/bin/aerospace}
target_id=${AEROSPACE_WINDOW_ID:-}
[[ "$target_id" =~ ^[0-9]+$ ]] || exit 0

# 連続して開いたときにも、ツリーの組み直しが重ならないよう直列化する。
# 待機側もロック取得後に一覧を読み直すので、最後の追加を取りこぼさない。
lock_dir="${TMPDIR:-/tmp}/aerospace-auto-grid-${UID}.lock"
locked=false
for ((attempt = 0; attempt < 50; attempt++)); do
  if mkdir "$lock_dir" 2>/dev/null; then
    locked=true
    break
  fi
  sleep 0.1
done
[[ "$locked" == true ]] || exit 0
trap 'rmdir "$lock_dir"' EXIT
trap 'exit 1' HUP INT TERM

# 後続の on-window-detected による WS 移動・floating 化を待つ。
sleep 0.2
windows=$("$AEROSPACE" list-windows --all --format '%{window-id}|%{workspace}|%{window-layout}')
workspace=''
while IFS='|' read -r wid ws window_layout; do
  if [[ "$wid" == "$target_id" ]]; then
    [[ "$window_layout" != floating ]] || exit 0
    workspace=$ws
    break
  fi
done <<<"$windows"
[[ -n "$workspace" ]] || exit 0

ids=()
while IFS='|' read -r wid ws window_layout; do
  [[ "$ws" == "$workspace" ]] || continue
  # Aqua Voice など、タイル管理外のオーバーレイは数に含めない。
  [[ "$window_layout" != floating ]] || continue
  ids+=("$wid")
done <<<"$windows"

count=${#ids[@]}
((count >= 2 && count <= 4)) || exit 0

"$AEROSPACE" flatten-workspace-tree --workspace "$workspace"
"$AEROSPACE" layout --workspace "$workspace" --root h_tiles

# list-windows の出力は画面上の順番ではない。ID 順に並べ直してペアを確定する。
ordered=$("$AEROSPACE" list-windows --workspace "$workspace" --format '%{window-id}|%{window-layout}' | sort -t '|' -k1,1n)
ids=()
while IFS='|' read -r wid window_layout; do
  [[ "$window_layout" != floating ]] || continue
  [[ "$wid" =~ ^[0-9]+$ ]] || exit 0
  ids+=("$wid")
done <<<"$ordered"
# 整列途中に枚数が変わった場合、古い ID で join しない。
((${#ids[@]} == count)) || exit 0

# 大きい ID から左端へ寄せると、最終的に左から ID の昇順になる。
# 左端に到達すると move は失敗するので、そのウィンドウの移動を終了する。
for ((i = count - 1; i >= 0; i--)); do
  for ((step = 1; step < count; step++)); do
    "$AEROSPACE" move --window-id "${ids[i]}" --boundaries workspace left || break
  done
done

case "$count" in
  3)
    "$AEROSPACE" join-with --window-id "${ids[1]}" right
    ;;
  4)
    "$AEROSPACE" join-with --window-id "${ids[0]}" right
    "$AEROSPACE" join-with --window-id "${ids[2]}" right
    ;;
esac
"$AEROSPACE" balance-sizes --workspace "$workspace"
