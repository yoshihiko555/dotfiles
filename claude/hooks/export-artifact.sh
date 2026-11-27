#!/usr/bin/env bash

# Claude Code PostToolUse hook（matcher: Artifact）: 公開した Artifact のファイルを書き出し先へ写し、
# 削除した Artifact は書き出し先からも消す。
# 書き出し先は homebase のナレッジの取り込み元フォルダとして登録する。
# - 1 本の Artifact を <書き出し先>/<URL の末尾の ID>/ に置く。本体のページは index.html、
#   files で添えたファイル（2 枚目以降のページ・CSS・画像など）は公開したときのパスに置く
# - 再公開では渡されたファイルだけを上書きし、files で null にしたものは消す
# - 書きかけを取り込ませないため、.tmp に書いてから名前を変える
set -euo pipefail

dest_dir="${CLAUDE_ARTIFACTS_EXPORT_DIR:-$HOME/claude-artifacts}"

input="$(cat)"
problems=()

report() {
  local IFS='／'
  jq -cn --arg msg "⚠️ Artifact の書き出しに失敗しました: $*" '{systemMessage: $msg}'
}

warn() {
  report "$1"
  exit 0
}

field() {
  jq -r "$1 // empty" <<<"$input" 2>/dev/null || true
}

response() {
  field ".tool_response | if type == \"string\" then (fromjson? // {}) else . end | $1"
}

# https://claude.ai/artifact/<ID> から <ID> を取り出して slug に入れる
parse_slug() {
  [[ "$1" =~ ^https://claude\.ai/(code/)?artifact/([A-Za-z0-9_-]+)/?([?#].*)?$ ]] || warn "想定外の URL（$1）"
  slug="${BASH_REMATCH[2]}"
}

resolve() {
  if [[ "$1" == /* ]]; then
    printf '%s' "$1"
  else
    printf '%s/%s' "$2" "$1"
  fi
}

copy_into() {
  local src="$1" dest="$2" tmp
  mkdir -p "$(dirname "$dest")" || return 1
  tmp="$dest.$$.tmp"
  if ! { cp "$src" "$tmp" && mv -f "$tmp" "$dest"; }; then
    rm -f "$tmp"
    return 1
  fi
}

[[ "$(field '.tool_name')" == "Artifact" ]] || exit 0

case "$(field '.tool_input.action')" in
  "" | publish) ;;
  delete)
    [[ "$(response '.artifact_delete.deleted')" == "true" ]] || exit 0
    url="$(response '.artifact_delete.url')"
    [[ -n "$url" ]] || exit 0
    parse_slug "$url"
    rm -rf "${dest_dir:?}/$slug" || warn "$dest_dir/$slug を消せない"
    exit 0
    ;;
  *) exit 0 ;;
esac

# アセットのアップロードと、型から作る Artifact は対象外
[[ "$(field '.tool_input.asset')" != "true" ]] || exit 0
[[ -z "$(field '.tool_input.type_url')" ]] || exit 0

url="$(response '.url')"
# 公開が拒まれたときは URL が返らない
[[ -n "$url" ]] || exit 0
parse_slug "$url"
art_dir="$dest_dir/$slug"
cwd="$(field '.cwd')"

file_path="$(field '.tool_input.file_path')"
if [[ -n "$file_path" ]]; then
  # .md の公開や、型から作った Artifact のデータファイルは対象外
  shopt -s nocasematch
  [[ "$file_path" =~ \.html?$ ]] || exit 0
  shopt -u nocasematch
  src="$(resolve "$file_path" "$cwd")"
  [[ -f "$src" ]] || warn "公開したファイルが見つからない（$src）"
  copy_into "$src" "$art_dir/index.html" || warn "$art_dir/index.html に写せない"
elif [[ ! -f "$art_dir/index.html" ]]; then
  # 本体を写していない Artifact（型から作ったものなど）へのファイルの追加は対象外
  exit 0
fi

root="$(field '.tool_input.root')"
base="$cwd"
[[ -z "$root" ]] || base="$(resolve "$root" "$cwd")"

# files の各要素を「公開パス<TAB>種類<TAB>元のファイル」に並べる
while IFS=$'\t' read -r published kind source; do
  if [[ -z "$published" || "$published" == /* || "/$published/" == */../* ]]; then
    problems+=("想定外のパス（$published）")
    continue
  fi
  case "$kind" in
    remove)
      rm -f "$art_dir/$published" || problems+=("$published を消せない")
      ;;
    local)
      src="$(resolve "$source" "$base")"
      if ! { [[ -f "$src" ]] && copy_into "$src" "$art_dir/$published"; }; then
        problems+=("$published を写せない")
      fi
      ;;
    *)
      problems+=("$published は別の Artifact から複製したので写せない（同期で取り直す）")
      ;;
  esac
done < <(jq -r '
  .tool_input.files // empty
  | if type == "object" then
      to_entries[]
      | [.key] + (
          if .value == null then ["remove", ""]
          elif (.value | type) == "string" then ["local", .value]
          elif (.value | type) == "object" and (.value | has("from")) then ["local", .value.from]
          else ["remote", ""]
          end)
    elif type == "array" then .[] | [.path, "local", .path]
    else empty
    end
  | @tsv' <<<"$input" 2>/dev/null)

if ((${#problems[@]} > 0)); then
  report "${problems[@]}"
fi
