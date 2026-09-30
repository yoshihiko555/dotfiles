#!/bin/bash
# デフォルト配置: aerospace.toml の on-window-detected にある
# 「app-id → move-node-to-workspace」ルールを、既に開いているウィンドウへ一括適用する。
# AeroSpace 起動前から開いていたウィンドウを揃え直すため after-startup-command から呼ぶ。
#
# 対応表は aerospace.toml だけを正とする（2026-09-30 にスクリプト内の重複表を廃止）。
# 次のブロックは起動時に評価できないため対象外にする:
#   - if.app-id 以外の条件（if.window-title-regex-substring 等）を持つブロック
#   - run に move-node-to-workspace を含まないブロック（floating 化など）
# 同じ app-id が複数あるときは、AeroSpace と同じく先に書いたルールを採用する。

set -u

AEROSPACE=${AEROSPACE_BIN:-/opt/homebrew/bin/aerospace}
CONFIG=${AEROSPACE_CONFIG:-"$(dirname "$0")/../aerospace.toml"}

if [[ ! -r "$CONFIG" ]]; then
  echo "${0##*/}: 設定ファイルを読めません: $CONFIG" >&2
  exit 1
fi

# aerospace.toml から「app-id|ワークスペース」を 1 行ずつ出力する。
# 当リポジトリの書式（1 キー 1 行・シングルクォート）を前提にした簡易パーサー。
# 書式の前提が崩れたときは tests/test_default_layout.py で検出する。
list_rules() {
  awk -v q="'" '
    function flush() {
      if (in_block && app != "" && ws != "" && other_if == 0) print app "|" ws
      app = ""; ws = ""; other_if = 0
    }
    /^\[\[on-window-detected\]\]/ { flush(); in_block = 1; next }
    /^\[/                         { flush(); in_block = 0; next }
    !in_block                     { next }
    /^if\.app-id[ \t]*=/          { split($0, parts, q); app = parts[2]; next }
    /^if\./                       { other_if++; next }
    /^run[ \t]*=/ && match($0, /move-node-to-workspace [A-Za-z0-9_-]+/) {
      split(substr($0, RSTART, RLENGTH), parts, " "); ws = parts[2]
    }
    END { flush() }
  ' "$CONFIG"
}

windows=$("$AEROSPACE" list-windows --all --format '%{window-id}|%{app-bundle-id}|%{workspace}') || exit 1

# app-id は完全一致で照合する（旧実装の grep -F は前方一致する別アプリも巻き込んだ）。
# 既に目的の WS にいるウィンドウは動かさない（起動直後の無駄な再描画を減らす）。
moves=$(awk -F'|' '
  NR == FNR { if (!($1 in target)) target[$1] = $2; next }
  ($2 in target) && $3 != target[$2] { print $1 " " target[$2] }
' <(list_rules) <(printf '%s\n' "$windows"))

while read -r wid ws; do
  [[ -n "$wid" ]] || continue
  "$AEROSPACE" move-node-to-workspace --window-id "$wid" "$ws"
done <<<"$moves"

"$AEROSPACE" workspace M1
