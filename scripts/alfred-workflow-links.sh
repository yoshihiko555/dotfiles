#!/usr/bin/env bash
# Alfred の同期フォルダ（Dropbox）の workflows/ に、repo の alfred/<名前> へのリンクを張る。
#
#     alfred-workflow-links.sh apply <UUID>=<名前> ...
#
#   リンク先が一致していれば何もしない。Dropbox は File Provider のため、一覧・作成・削除には
#   アプリごとの許可が要る。触るのは対象パスの readlink だけにして、変更が無い switch では
#   許可を要らなくする。許可が無くて書けないときは非 0 で止める（握りつぶさない）。
#
#   表から消したワークフローのリンクは、前回張った UUID の記録（ALFRED_LINKS_STATE）から
#   見つけて消す。消すのは alfred/ 配下を指しているリンクだけ。
#
#   環境変数:
#     ALFRED_WORKFLOWS_DIR  Alfred の workflows/（既定: Dropbox の同期フォルダ）
#     ALFRED_SRC_DIR        リンク先の alfred/（既定: このスクリプトの repo）
#     ALFRED_LINKS_STATE    前回張った UUID の記録

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
workflows_dir="${ALFRED_WORKFLOWS_DIR:-$HOME/Dropbox/01_Private/05_Settings/02_Alfred/Alfred.alfredpreferences/workflows}"
src_dir="${ALFRED_SRC_DIR:-$repo_root/alfred}"
state_file="${ALFRED_LINKS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/dotfiles/alfred-workflow-links}"

die() {
  echo "alfred-workflow-links: $*" >&2
  exit 1
}

cannot_change() {
  die "$1 を変更できない。Dropbox のフォルダへの書き込みが拒否されていないか確認する（ls ~/Library/CloudStorage/Dropbox で許可を出し直す。ダイアログが出なければ tccutil reset FileProviderDomain com.mitchellh.ghostty の後にもう一度）"
}

if [[ "${1:-}" != apply || $# -lt 2 ]]; then
  echo "usage: $(basename "$0") apply <UUID>=<名前> ..." >&2
  exit 2
fi
shift

# 同期先が動いたときに偽のツリーを作らないよう、workflows/ は作らない
[[ -d "$workflows_dir" ]] || die "workflows ディレクトリが無い: $workflows_dir"

uuids=()
names=()
for pair in "$@"; do
  uuid="${pair%%=*}"
  name="${pair#*=}"
  [[ "$uuid" =~ ^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$ ]] \
    || die "UUID の形式が違う: $pair"
  [[ -n "$name" && "$name" != "$pair" && -d "$src_dir/$name" ]] \
    || die "リンク先が無い: $src_dir/$name"
  uuids+=("$uuid")
  names+=("$name")
done

is_wanted() {
  local u
  for u in "${uuids[@]}"; do
    [[ "$u" == "$1" ]] && return 0
  done
  return 1
}

# 表から消した分の後始末
if [[ -f "$state_file" ]]; then
  while read -r uuid; do
    [[ -z "$uuid" ]] && continue
    is_wanted "$uuid" && continue
    target="$workflows_dir/user.workflow.$uuid"
    [[ -L "$target" ]] || continue
    current="$(readlink "$target" || true)"
    if [[ "$current" == "$src_dir"/* ]]; then
      echo "alfred-workflow-links: 表から消えたリンクを消す: $target"
      rm "$target" || cannot_change "$target"
    else
      echo "alfred-workflow-links: alfred/ を指していないので残す: $target -> $current" >&2
    fi
  done <"$state_file"
fi

for i in "${!uuids[@]}"; do
  target="$workflows_dir/user.workflow.${uuids[i]}"
  want="$src_dir/${names[i]}"
  if [[ -L "$target" ]]; then
    [[ "$(readlink "$target" || true)" == "$want" ]] && continue
  elif [[ -e "$target" ]]; then
    die "リンクではない実体があるので触らない: $target"
  fi
  echo "alfred-workflow-links: $target -> $want"
  ln -sfn "$want" "$target" || cannot_change "$target"
done

# 全部張れたときだけ記録を更新する
mkdir -p "$(dirname "$state_file")"
printf '%s\n' "${uuids[@]}" >"$state_file.tmp"
mv "$state_file.tmp" "$state_file"
