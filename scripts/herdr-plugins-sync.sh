#!/usr/bin/env bash
# herdr プラグインを config/herdr/plugins.txt の固定リストに揃える。
#
#     apply … 未導入、または SHA が違うプラグインを herdr plugin install --ref で入れる
#     check … 差分を表示するだけ（何も入れない）
#
#   herdr plugin install は ~/.config/herdr/plugins/ へ clone して登録簿を作る命令的な
#   操作なので、home-manager の activation から呼ぶ。herdr サーバーが動いていなくても動く。
#   リストから消したプラグインを削除することはしない（追加・更新のみ）。
#   外すときは herdr plugin uninstall <id> を手で実行してからリストから消す。

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
list_file="$repo_root/config/herdr/plugins.txt"
HERDR="${HERDR:-herdr}"
mode="${1:-apply}"

case "$mode" in
  apply | check) ;;
  *)
    echo "usage: $(basename "$0") [apply|check]" >&2
    exit 2
    ;;
esac

if ! command -v "$HERDR" >/dev/null 2>&1; then
  echo "herdr-plugins-sync: herdr が見つからないのでスキップ" >&2
  exit 0
fi

installed="$("$HERDR" plugin list 2>/dev/null || true)"
status=0

while read -r slug sha _; do
  [[ -z "$slug" || "$slug" == \#* ]] && continue
  if [[ ! "$sha" =~ ^[0-9a-f]{40}$ ]]; then
    echo "herdr-plugins-sync: $slug の SHA が 40 桁ではない: $sha" >&2
    status=1
    continue
  fi
  # plugin list は "[github:<owner/repo>@<sha>]" の形で導入元を出す
  if [[ "$installed" == *"[github:$slug@$sha]"* ]]; then
    continue
  fi
  if [[ "$mode" == check ]]; then
    echo "差分: $slug を $sha に揃える必要がある"
    status=1
    continue
  fi
  echo "herdr-plugins-sync: $slug を $sha で導入する"
  if ! "$HERDR" plugin install "$slug" --ref "$sha" --yes >/dev/null; then
    echo "herdr-plugins-sync: $slug の導入に失敗した（ネットワーク等。次の switch で再試行）" >&2
    status=1
  fi
done <"$list_file"

exit "$status"
