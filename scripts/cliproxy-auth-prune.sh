#!/usr/bin/env bash
# CLIProxyAPI の認証ファイルのうち、新しい認証に置き換わって不要になった
# 失効ファイルを削除する。
#
#   cliproxyapi --codex-login 等はバージョンによってファイル名の付け方が変わり
#   (例: codex-<mail>-<plan>.json → codex-<id>-<mail>-<plan>.json)、
#   再認証しても古いファイルが残る。プロキシは disabled=false のそれも有効な
#   候補として掴むため、当たると 503 auth_unavailable になる。
#
# 削除条件は「同じ type に有効な認証が別に存在する」ことのみ。
# expired は access token の期限であって refresh token で復活しうるため、
# その type で唯一の認証は、失効していても削除しない。
#
# 使い方:
#   scripts/cliproxy-auth-prune.sh          確認のみ (既定)
#   scripts/cliproxy-auth-prune.sh --yes    実際に削除してサービスを再起動
set -euo pipefail

DIR="${CLIPROXY_AUTH_DIR:-$HOME/.cli-proxy-api}"
APPLY=0
[ "${1:-}" = "--yes" ] && APPLY=1

if [ ! -d "$DIR" ]; then
  echo "  認証ディレクトリがありません: $DIR"
  exit 0
fi

# 各ファイルを "PRUNE|KEEP<TAB>path<TAB>type<TAB>期限日" に分類する。
decisions=$(
  python3 - "$DIR" <<'PY'
import datetime, glob, json, os, sys

now = datetime.datetime.now(datetime.timezone.utc)
entries = []
for path in sorted(glob.glob(os.path.join(sys.argv[1], "*.json"))):
    try:
        data = json.load(open(path))
    except Exception:
        continue
    expired = data.get("expired")
    if not expired:
        continue
    try:
        when = datetime.datetime.fromisoformat(expired)
    except ValueError:
        continue
    entries.append((path, data.get("type", "?"), when, expired[:10]))

alive = {kind for _, kind, when, _ in entries if when > now}
for path, kind, when, day in entries:
    verdict = "PRUNE" if when <= now and kind in alive else "KEEP"
    print("\t".join((verdict, path, kind, day)))
PY
)

found=0
while IFS=$'\t' read -r verdict path kind day; do
  [ -n "${verdict:-}" ] || continue
  base=$(basename "$path")
  if [ "$verdict" = "PRUNE" ]; then
    found=1
    if [ "$APPLY" = 1 ]; then
      rm -- "$path"
      echo "  削除: $base ($day に失効、有効な $kind が別にある)"
    else
      echo "  削除候補: $base ($day に失効、有効な $kind が別にある)"
    fi
  fi
done <<<"$decisions"

if [ "$found" = 0 ]; then
  echo "  不要な失効ファイルはありません"
elif [ "$APPLY" = 1 ]; then
  brew services restart cliproxyapi
  echo "✅ サービス再起動完了"
else
  echo ""
  echo "  実際に削除するには: task cliproxy-auth-prune -- --yes"
fi
