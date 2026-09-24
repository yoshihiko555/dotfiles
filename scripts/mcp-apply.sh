#!/usr/bin/env bash
# 旧コマンドの互換入口。定義の正典は shared/mcp/servers/ に統一する。
set -euo pipefail
action=sync
for arg in "$@"; do
  case "$arg" in
    --dry-run) action=diff ;;
    --force) echo "--force は不要です。同期は差分だけを反映します。" >&2 ;;
    *)
      echo "未対応の引数: $arg" >&2
      exit 1
      ;;
  esac
done
exec bash "$(dirname "${BASH_SOURCE[0]}")/mcp-manage.sh" "$action"
