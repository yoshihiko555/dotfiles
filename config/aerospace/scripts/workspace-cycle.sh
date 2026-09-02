#!/bin/bash
# フォーカス中のモニター内でワークスペースを巡回する（macOS の ctrl-←/→ 相当）
#
# 背景:
#   AeroSpace 標準の `workspace next|prev` は全 9 ワークスペースを
#   アルファベット順（B1→B2→M1→…→S3）に巡回するため、3 回押すごとに
#   フォーカスが別モニターへ飛んでしまう。
#   `--stdin` で巡回対象のリストを渡せるので、`list-workspaces --monitor focused`
#   の出力を食わせて「今いるモニターのワークスペースだけ」に限定する。
#
# 使い方:
#   workspace-cycle.sh next   # M1 → M2 → M3 → M4 → M1（メイン DELL の場合）
#   workspace-cycle.sh prev
#
# BTT のトラックパッドスワイプからも同じスクリプトを呼ぶため、
# PATH に依存しないよう aerospace の絶対パスを使う。

set -u

AEROSPACE=/opt/homebrew/bin/aerospace

direction="${1:-next}"
case "$direction" in
  next | prev) ;;
  *)
    echo "usage: ${0##*/} (next|prev)" >&2
    exit 1
    ;;
esac

# --wrap-around: 端で止まらず反対側へ回り込む（モニター移動 alt-shift-←/→ と同方針）
"$AEROSPACE" list-workspaces --monitor focused \
  | "$AEROSPACE" workspace --wrap-around --stdin "$direction"
