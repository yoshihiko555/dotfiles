#!/usr/bin/env bash
# BetterTouchTool のトリガー設定を repo と同期する。
#
#   BTT の設定実体は SQLite（~/Library/Application Support/BetterTouchTool/
#   btt_data_store.version_*）で、ファイル名にバージョン番号が埋まるため
#   symlink では管理できない。代わりに AppleScript API 経由で JSON を出し入れする。
#
#     export … 実機 → repo（config/btt/triggers.json へ回収）
#     apply  … repo → 実機（親トリガーを UUID で照合して update / add）
#
#   repo から消えたトリガーを実機から削除することはしない（追加・更新のみ）。
#   GUI で足した設定が switch で消える事故を避けるため。不要になったものは
#   GUI で消してから export で回収する。

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
triggers_json="$repo_root/config/btt/triggers.json"
reference_json="${XDG_STATE_HOME:-$HOME/.local/state}/btt/triggers.applied.json"

JQ="${JQ:-jq}"
OSASCRIPT="${OSASCRIPT:-/usr/bin/osascript}"

btt_running() {
  /usr/bin/pgrep -x BetterTouchTool >/dev/null 2>&1
}

# AppleScript の文字列リテラルへ埋め込める形へエスケープする
as_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

btt_get_triggers() {
  "$OSASCRIPT" -e 'tell application "BetterTouchTool" to get_triggers "{\"trigger_parent_uuid\":\"\"}"'
}

btt_get_trigger() {
  "$OSASCRIPT" -e "tell application \"BetterTouchTool\" to get_trigger \"$(as_escape "$1")\""
}

# update_trigger は UUID + json キーワード引数、add_new_trigger は JSON の
# 位置引数を取る。呼び出し形式が違うので別々に包む。
btt_update_trigger() {
  local uuid="$1" json_file="$2" json
  json="$(as_escape "$("$JQ" -c . "$json_file")")"
  "$OSASCRIPT" -e "tell application \"BetterTouchTool\" to update_trigger \"$(as_escape "$uuid")\" json \"$json\""
}

btt_add_new_trigger() {
  local json_file="$1" json
  json="$(as_escape "$("$JQ" -c . "$json_file")")"
  "$OSASCRIPT" -e "tell application \"BetterTouchTool\" to add_new_trigger \"$json\""
}

# repo に載せる形へ整える。
#
#   BTTLastUpdatedAt はトリガーを触らなくても BTT 側で更新されるため全階層で
#   落とす。BTTUUID でソートして出力順のゆらぎも吸収する。
#   BTTOrder（GUI の並び順）は落とさない。落とすと apply が古い並び順を
#   送り返して GUI での並べ替えが黙って巻き戻るため、他の項目と同様に
#   「変えたら drift、export で回収」で扱う。
normalize() {
  "$JQ" -S '
    [ .[] ]
    | walk(if type == "object" then del(.BTTLastUpdatedAt) else . end)
    | sort_by(.BTTUUID)
  '
}

# 初回管理時（参照コピーが無い）の安全判定。
#
#   削除はしない方針なので、実機にしか無いトリガーは放置されるし、repo に
#   しか無いものは追加されるだけ。危険なのは「同じ UUID が両側にあって中身が
#   違う」場合（repo が実機の未回収の変更を潰す）だけなので、そこだけ見る。
#   全体一致を要求すると、まっさらな新規マシンで必ず拒否されてしまう。
first_run_safe() {
  "$JQ" -n -e --slurpfile c "$1" --slurpfile r "$2" '
    ($c[0] | map({ key: .BTTUUID, value: . }) | from_entries) as $cm
    | all($r[0][]; ($cm[.BTTUUID] == null) or (. == $cm[.BTTUUID]))
  ' >/dev/null 2>&1
}

# 実機の現況を親トリガーの配列として取り出す。
#
#   get_triggers は BTTEnabled:0（GUI で無効化した）トリガーを返さない。一方
#   その子アクション（BTTIsPureAction）はトップレベルに現れるので、子の
#   BTTTriggerParentUUID から親を逆引きして get_trigger で個別に補完する。
#   これを省くと、無効化しただけの設定が export から丸ごと消える。
#
#   BTTBelongsToApp（Finder / Browsers 等のスコープ）は get_triggers の一覧に
#   しか付かず get_trigger では返らないため、補完した親には子側の値を移す。
#
#   BTTBelongsToApp が "Trash" のものは BTT のゴミ箱に入っている削除済み設定
#   なので、設定ではないと見なして除外する。
collect_current() {
  local raw parents orphan_ids uuid one merged app
  raw="$(mktemp)"
  parents="$(mktemp)"

  btt_get_triggers >"$raw"

  "$JQ" '[.[] | select(.BTTIsPureAction != true) | select(.BTTBelongsToApp != "Trash")]' \
    "$raw" >"$parents"

  orphan_ids="$("$JQ" -r '
    ([.[] | select(.BTTIsPureAction != true) | .BTTUUID]) as $listed
    | [ .[]
        | select(.BTTIsPureAction == true)
        | select(.BTTTriggerParentUUID != null)
        | select(.BTTTriggerParentUUID as $p | $listed | index($p) == null)
        | .BTTTriggerParentUUID
      ] | unique | .[]
  ' "$raw")"

  for uuid in $orphan_ids; do
    one="$(mktemp)"
    if ! btt_get_trigger "$uuid" >"$one" 2>/dev/null \
      || ! "$JQ" -e '.BTTUUID? // empty' "$one" >/dev/null 2>&1; then
      # 削除済みの UUID には {} が返る。取り込まない
      rm -f "$one"
      continue
    fi

    app="$("$JQ" -r --arg u "$uuid" '
      [.[] | select(.BTTTriggerParentUUID == $u) | .BTTBelongsToApp]
      | map(select(. != null)) | first // ""
    ' "$raw")"

    if [ "$app" = "Trash" ]; then
      rm -f "$one"
      continue
    fi

    merged="$(mktemp)"
    "$JQ" --arg app "$app" \
      'if $app == "" then . else .BTTBelongsToApp = $app end' "$one" >"$merged"
    "$JQ" -s '.[0] + [.[1]]' "$parents" "$merged" >"$parents.new"
    mv "$parents.new" "$parents"
    rm -f "$one" "$merged"
  done

  normalize <"$parents"
  rm -f "$raw" "$parents"
}

cmd_export() {
  btt_running || {
    echo "error: btt: BetterTouchTool が起動していません" >&2
    exit 1
  }
  local current
  current="$(mktemp)"
  collect_current >"$current"

  if [ -f "$triggers_json" ] && cmp -s "$current" "$triggers_json"; then
    echo "btt: drift なし"
    rm -f "$current"
    return 0
  fi

  mkdir -p "$(dirname "$triggers_json")"
  install -m 0644 "$current" "$triggers_json"
  rm -f "$current"
  echo "btt: repo へ回収しました -> ${triggers_json#"$repo_root"/}"
  echo "内容を確認後、nix-darwin を switch すると参照コピーが更新されます。"
}

cmd_apply() {
  btt_running || {
    echo "warning: btt: BetterTouchTool が起動していないためスキップしました。" >&2
    return 0
  }
  if [ ! -f "$triggers_json" ]; then
    echo "warning: btt: repo 側の triggers.json がないためスキップしました。" >&2
    return 0
  fi
  if ! "$JQ" -e 'type == "array"' "$triggers_json" >/dev/null 2>&1; then
    echo "warning: btt: repo 側が不正な JSON のため適用を拒否しました。" >&2
    return 0
  fi

  local current
  current="$(mktemp)"
  collect_current >"$current"

  if [ -f "$reference_json" ]; then
    # 参照コピーと現況が食い違う = GUI で触られている。ただし現況が repo と
    # 一致していれば task btt-export で回収済みなので、そのまま適用へ進んで
    # 参照コピーを追いつかせる（ここで弾くと回収後も警告が出続ける）。
    if ! cmp -s "$current" "$reference_json" \
      && ! cmp -s "$current" "$triggers_json"; then
      echo "warning: btt の drift を検出。上書きしません。" >&2
      echo "warning: task btt-export で repo へ回収してから再度 switch してください。" >&2
      rm -f "$current"
      return 0
    fi
  elif ! first_run_safe "$current" "$triggers_json"; then
    # 初回管理時、両側にある UUID の中身が食い違うならどちらが正か判断できない
    echo "warning: btt: 初回管理時の実機の内容が repo と異なるため適用しません。" >&2
    echo "warning: 内容を確認し、task btt-export で回収してください。" >&2
    rm -f "$current"
    return 0
  fi

  local count i=0 uuid one updated=0 added=0
  count="$("$JQ" 'length' "$triggers_json")"
  while [ "$i" -lt "$count" ]; do
    one="$(mktemp)"
    "$JQ" ".[$i]" "$triggers_json" >"$one"
    uuid="$("$JQ" -r '.BTTUUID' "$one")"

    if "$JQ" -e --arg u "$uuid" 'any(.[]; .BTTUUID == $u)' "$current" >/dev/null 2>&1; then
      btt_update_trigger "$uuid" "$one" >/dev/null
      updated=$((updated + 1))
    else
      btt_add_new_trigger "$one" >/dev/null
      added=$((added + 1))
    fi
    rm -f "$one"
    i=$((i + 1))
  done

  mkdir -p "$(dirname "$reference_json")"
  collect_current >"$reference_json"
  chmod 0644 "$reference_json"
  rm -f "$current"
  echo "btt: 更新 $updated 件 / 追加 $added 件"
}

case "${1:-}" in
  export) cmd_export ;;
  apply) cmd_apply ;;
  *)
    echo "usage: bash scripts/btt-sync.sh export|apply" >&2
    exit 2
    ;;
esac
