#!/usr/bin/env bash
# Loupedeck Live のプロファイルを repo と同期する。
#
#   Loupedeck Live は Logi Options+ 配下の LogiPluginService が管理しており、
#   プロファイルの実体は
#     ~/Library/Application Support/Logi/LogiPluginService/Applications/Loupedeck50/
#   にアプリ別ディレクトリ（@_defaultmac / @_photoshop …）として置かれる。
#   中身は JSON + アイコン PNG のみで、絶対パスやマシン固有 ID は含まない。
#
#   サービスは起動時にこのツリーを丸ごと書き戻す（内容はバイト一致）うえ、
#   設定ファイルには「稼働中に編集するな」と明記されているため、symlink
#   ではなく BTT と同じ snapshot 方式を採る。
#
#     export … 実機 → repo（config/loupedeck/Loupedeck50/ へ回収）
#     apply  … repo → 実機（サービスを止めてツリーを差し替え、再起動）
#     status … drift の有無だけ表示（task status 用）
#
#   apply は「参照ハッシュ（前回 apply 時の内容）と実機が一致する」ときだけ
#   上書きする。GUI で編集した未回収の変更を switch で潰さないための安全弁で、
#   drift 中は警告して抜ける。回収は task loupedeck-export。
#
#   秘匿情報を含む PluginSettings/*.dat（Spotify / Twitch 等のトークン）や
#   LoupedeckSettings.ini は対象外。Loupedeck50 配下のプロファイルのみ扱う。
#
#   回収先 config/loupedeck/ は .gitignore 済み。ボタンに設定した URL やマクロ
#   内容など私的な情報が入るため public リポジトリには載せず、ローカルコピー
#   として保持する（別マシンへ持ち込むときは手動でディレクトリごとコピー）。

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
device="Loupedeck50" # Loupedeck Live の内部デバイス名
repo_dir="$repo_root/config/loupedeck/$device"
live_dir="$HOME/Library/Application Support/Logi/LogiPluginService/Applications/$device"
reference_file="${XDG_STATE_HOME:-$HOME/.local/state}/loupedeck/$device.applied.sha256"

service_bundle_id="com.logi.pluginservice"
service_app="/Applications/Utilities/LogiPluginService.app"
service_label="com.logi.pluginservice.launch"

RSYNC="${RSYNC:-rsync}"
SHASUM="${SHASUM:-/usr/bin/shasum}"

# ツリー全体の内容ハッシュ。相対パスと各ファイルの sha256 を並べて再度 sha256。
# .DS_Store は Finder が勝手に作るので無視する。
tree_hash() {
  (
    cd "$1" \
      && find . -type f ! -name .DS_Store -print0 \
      | sort -z \
        | xargs -0 "$SHASUM" -a 256 \
        | "$SHASUM" -a 256 \
        | cut -d' ' -f1
  )
}

sync_tree() {
  "$RSYNC" -a --delete --exclude .DS_Store "$1/" "$2/"
}

service_running() {
  /usr/bin/pgrep -x LogiPluginService >/dev/null 2>&1
}

wait_service() {
  # $1 = running|stopped、$2 = 秒数
  local want="$1" i=0
  while [ "$i" -lt "$2" ]; do
    if [ "$want" = running ] && service_running; then return 0; fi
    if [ "$want" = stopped ] && ! service_running; then return 0; fi
    sleep 1
    i=$((i + 1))
  done
  return 1
}

stop_service() {
  service_running || return 0
  /usr/bin/osascript -e "tell application id \"$service_bundle_id\" to quit" >/dev/null 2>&1 || true
  if ! wait_service stopped 10; then
    /usr/bin/pkill -x LogiPluginService || true
    wait_service stopped 5 || {
      echo "error: loupedeck: LogiPluginService を停止できませんでした" >&2
      return 1
    }
  fi
}

start_service() {
  service_running && return 0
  # launchd の launch agent 経由で上げ直す。効かなければアプリとして直接起動
  /bin/launchctl kickstart "gui/$(id -u)/$service_label" >/dev/null 2>&1 || true
  if ! wait_service running 5; then
    /usr/bin/open -g -a "$service_app" --args -noui >/dev/null 2>&1 || true
    wait_service running 10 || {
      echo "warning: loupedeck: LogiPluginService が再起動しませんでした。Logi Options+ を開き直してください。" >&2
      return 0
    }
  fi
}

require_live() {
  if [ ! -d "$live_dir" ]; then
    echo "$1: loupedeck: 実機側のプロファイルがありません（Logi Options+ 未導入か Loupedeck 未接続）: ${live_dir#"$HOME"/}" >&2
    return 1
  fi
}

cmd_export() {
  require_live error || exit 1
  local h_live h_repo
  h_live="$(tree_hash "$live_dir")"
  if [ -d "$repo_dir" ]; then
    h_repo="$(tree_hash "$repo_dir")"
    if [ "$h_live" = "$h_repo" ]; then
      echo "loupedeck: drift なし"
      return 0
    fi
  fi

  mkdir -p "$repo_dir"
  sync_tree "$live_dir" "$repo_dir"
  echo "loupedeck: repo へ回収しました -> ${repo_dir#"$repo_root"/}"
  echo "内容を確認後、nix-darwin を switch すると参照ハッシュが更新されます。"
}

cmd_apply() {
  require_live warning || return 0
  if [ ! -d "$repo_dir" ]; then
    echo "warning: loupedeck: repo 側の ${repo_dir#"$repo_root"/} がないためスキップしました。" >&2
    return 0
  fi

  local h_live h_repo h_ref=""
  h_live="$(tree_hash "$live_dir")"
  h_repo="$(tree_hash "$repo_dir")"
  [ -f "$reference_file" ] && h_ref="$(cat "$reference_file")"

  if [ "$h_live" = "$h_repo" ]; then
    # 回収直後や変更なし。参照ハッシュだけ追いつかせる
    mkdir -p "$(dirname "$reference_file")"
    printf '%s\n' "$h_repo" >"$reference_file"
    echo "loupedeck: 変更なし"
    return 0
  fi

  if [ -n "$h_ref" ]; then
    if [ "$h_live" != "$h_ref" ]; then
      echo "warning: loupedeck の drift を検出。上書きしません。" >&2
      echo "warning: task loupedeck-export で repo へ回収してから再度 switch してください。" >&2
      return 0
    fi
  else
    # 初回管理時は実機が repo と一致していない限りどちらが正か判断できない
    echo "warning: loupedeck: 初回管理時の実機の内容が repo と異なるため適用しません。" >&2
    echo "warning: 内容を確認し、task loupedeck-export で回収してください。" >&2
    return 0
  fi

  local was_running=0
  service_running && was_running=1
  stop_service
  sync_tree "$repo_dir" "$live_dir"
  [ "$was_running" = 1 ] && start_service

  mkdir -p "$(dirname "$reference_file")"
  printf '%s\n' "$h_repo" >"$reference_file"
  local restarted=なし
  [ "$was_running" = 1 ] && restarted=あり
  echo "loupedeck: repo の内容を適用しました（サービス再起動: ${restarted}）"
}

cmd_status() {
  local label="Loupedeck"
  if [ ! -d "$live_dir" ]; then
    # Options+ の無いマシン（hermes 等）では対象外なので静かに抜ける
    return 0
  fi
  if [ ! -d "$repo_dir" ] || [ ! -f "$reference_file" ]; then
    echo "❌ $label: profile tree or reference is missing"
    return 0
  fi
  local h_live h_repo h_ref
  h_live="$(tree_hash "$live_dir")"
  h_repo="$(tree_hash "$repo_dir")"
  h_ref="$(cat "$reference_file")"
  if [ "$h_live" = "$h_repo" ]; then
    echo "✅ $label: managed snapshot (no drift)"
  elif [ "$h_live" = "$h_ref" ]; then
    echo "⚠️  $label: repo changed, run switch or task loupedeck-apply"
  else
    echo "⚠️  $label: drift detected, run task loupedeck-export"
  fi
}

case "${1:-}" in
  export) cmd_export ;;
  apply) cmd_apply ;;
  status) cmd_status ;;
  *)
    echo "usage: bash scripts/loupedeck-sync.sh export|apply|status" >&2
    exit 2
    ;;
esac
