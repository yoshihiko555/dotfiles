#!/usr/bin/env bash

# ~/claude-artifacts/（書き出し先）の一覧・削除・入れ替えを行う。
# 置き方は claude/hooks/export-artifact.sh と同じで、1 本の Artifact を <ID>/ に置き、本体は index.html。
#
#   local.sh list                         # ID<TAB>index.html の更新日<TAB>大きさ（KB）
#   local.sh remove <ID>...               # フォルダごと消す
#   local.sh install <ID> <保存先> <公開パス>...
#                                         # Artifact の read で保存したファイルから、公開パスの分だけで
#                                         # フォルダを作り直す（クラウドで消えたファイルは残らない）
set -euo pipefail

dest_dir="${CLAUDE_ARTIFACTS_EXPORT_DIR:-$HOME/claude-artifacts}"

die() {
  echo "local.sh: $*" >&2
  exit 1
}

check_id() {
  [[ "$1" =~ ^[A-Za-z0-9_-]+$ ]] || die "想定外の ID: $1"
}

check_path() {
  [[ -n "$1" && "$1" != /* && "/$1/" != */../* ]] || die "想定外のパス: $1"
}

cmd="${1:-}"
shift || true

case "$cmd" in
  list)
    [[ -d "$dest_dir" ]] || exit 0
    for dir in "$dest_dir"/*/; do
      [[ -f "$dir/index.html" ]] || continue
      id="$(basename "$dir")"
      printf '%s\t%s\t%s\n' "$id" "$(date -r "$dir/index.html" +%F)" "$(du -sk "$dir" | cut -f1)"
    done
    ;;
  remove)
    for id in "$@"; do
      check_id "$id"
      rm -rf "${dest_dir:?}/$id"
      echo "removed $id"
    done
    ;;
  install)
    (($# >= 3)) || die "install <ID> <保存先> <公開パス>..."
    id="$1"
    src_dir="$2"
    shift 2
    check_id "$id"
    [[ -d "$src_dir" ]] || die "保存先がない: $src_dir"
    # 名前が . で始まるフォルダは homebase が辿らないので、組み立て中のフォルダに使う
    tmp="$dest_dir/.$id.$$.tmp"
    old="$dest_dir/.$id.$$.old"
    trap 'rm -rf "$tmp" "$old"' EXIT
    mkdir -p "$tmp"
    for path in "$@"; do
      check_path "$path"
      [[ -f "$src_dir/$path" ]] || die "保存したファイルがない: $src_dir/$path"
      mkdir -p "$(dirname "$tmp/$path")"
      cp "$src_dir/$path" "$tmp/$path"
    done
    [[ -f "$tmp/index.html" ]] || die "index.html が含まれていない"
    if [[ -e "$dest_dir/$id" ]]; then
      mv "$dest_dir/$id" "$old"
    fi
    mv "$tmp" "$dest_dir/$id"
    echo "installed $id ($# files)"
    ;;
  *)
    die "使い方: local.sh list | remove <ID>... | install <ID> <保存先> <公開パス>..."
    ;;
esac
