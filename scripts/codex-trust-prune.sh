#!/usr/bin/env bash
# 存在しないプロジェクトの設定だけを削除する。既定は候補表示のみ。
set -euo pipefail
umask 077
apply=false
case "${1:-}" in
  "") [[ $# -eq 0 ]] || exit 1 ;;
  --apply)
    [[ $# -eq 1 ]] || exit 1
    apply=true
    ;;
  *)
    echo "使い方: trust prune [--apply]" >&2
    exit 1
    ;;
esac
config="${CODEX_CONFIG_PATH:-$HOME/.codex/config.toml}"
taplo_bin="${TAPLO_BIN:-taplo}"
backup_root="${TRUST_BACKUP_DIR:-$HOME/.local/state/dotfiles/trust-backups}"
command -v jq >/dev/null
if ! command -v "$taplo_bin" >/dev/null; then
  root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  if [[ -z "${TAPLO_BIN:-}" ]] && command -v nix >/dev/null; then
    exec nix shell --inputs-from "$root/config/nix" nixpkgs#taplo --command bash "$0" "$@"
  fi
  echo "taplo が必要です" >&2
  exit 1
fi
[[ -f "$config" ]] || {
  echo "設定が見つかりません: $config" >&2
  exit 1
}
target=$(realpath "$config")
work=$(mktemp -d "${TMPDIR:-/tmp}/trust-prune.XXXXXX")
staged=""
lock=""
cleanup() {
  [[ -z "$staged" ]] || rm -f "$staged"
  [[ -z "$lock" ]] || rmdir "$lock"
  rm -rf "$work"
}
trap cleanup EXIT
fail() {
  echo "エラー: $*" >&2
  exit 1
}
cp -p "$target" "$work/before"
"$taplo_bin" get -f "$work/before" -o json >"$work/before.json" 2>"$work/error" || fail "設定の TOML が不正です"
jq -j '.projects // {} | to_entries[] | select(.value.trust_level == "trusted" or .value.trust_level == "untrusted") | .key, "\u0000"' "$work/before.json" >"$work/paths"
: >"$work/missing.ndjson"
while IFS= read -r -d '' project; do
  [[ "$project" == /* && ! -e "$project" && ! -L "$project" ]] || continue
  # 権限不足で存在を確認できないパスは削除候補にしない。
  parent=$(dirname "$project")
  while [[ ! -e "$parent" && ! -L "$parent" && "$parent" != / ]]; do parent=$(dirname "$parent"); done
  [[ -d "$parent" && -x "$parent" ]] || continue
  jq -n --arg path "$project" '$path' >>"$work/missing.ndjson"
  printf '削除候補: %s\n' "$project"
done <"$work/paths"
jq -s . "$work/missing.ndjson" >"$work/missing.json"
count=$(jq length "$work/missing.json")
[[ "$count" != 0 ]] || {
  echo "削除候補なし"
  exit 0
}
$apply || {
  echo "${count} 件。削除する場合は trust prune --apply を実行してください。"
  exit 0
}

# 通常の quoted-key テーブルを除去し、全体の構文と意味を照合する。
jq -r '.[] | "[projects." + tojson' "$work/missing.json" >"$work/headers"
awk '
  NR == FNR { prefixes[$0]=1; next }
  /^[ \t]*\[/ {
    header=$0; sub(/^[ \t]*/, "", header); drop=0
    for (prefix in prefixes) {
      if (index(header, prefix "]") == 1 || index(header, prefix ".") == 1) drop=1
    }
  }
  !drop || /^[ \t]*(#|$)/ { print }
' "$work/headers" "$work/before" >"$work/after"
"$taplo_bin" get -f "$work/after" -o json >"$work/after.json" 2>"$work/error" || fail "未対応の TOML 表記のため変更しません"
jq -en --slurpfile before "$work/before.json" --slurpfile after "$work/after.json" --slurpfile missing "$work/missing.json" '
  def normalize: if .projects == {} then del(.projects) else . end;
  ($before[0] | reduce $missing[0][] as $path (. ; del(.projects[$path])) | normalize) == ($after[0] | normalize)
' >/dev/null || fail "対象外の設定が変わるため変更しません"

mkdir -p "$backup_root"
mkdir "$backup_root/.prune-lock" 2>/dev/null || fail "別の prune が実行中かロックが残っています"
lock="$backup_root/.prune-lock"
while IFS= read -r -d '' project; do
  [[ ! -e "$project" && ! -L "$project" ]] || fail "パスが再作成されました。候補を確認し直してください"
done < <(jq -j '.[] | ., "\u0000"' "$work/missing.json")
cmp -s "$target" "$work/before" || fail "設定が並行して変更されました"
backup=$(mktemp "$backup_root/config.XXXXXX")
mv "$backup" "$backup.before"
backup="$backup.before"
cp "$work/before" "$backup"
chmod 600 "$backup"
staged=$(mktemp "$(dirname "$target")/.trust-prune.XXXXXX")
cp -p "$target" "$staged"
cat "$work/after" >"$staged"
cmp -s "$target" "$work/before" || fail "設定が並行して変更されました"
mv -f "$staged" "$target"
staged=""
echo "設定から ${count} 件を削除しました。バックアップ: $backup"
