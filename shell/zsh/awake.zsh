# macOS 標準 caffeinate を必要な間だけ起動する。
# launchd に預けるため、呼び出したターミナルを閉じても継続する。
# 永続 plist は作らず、ログアウト・再起動後には自動起動しない。
awake() {
  if [[ "$OSTYPE" != darwin* ]]; then
    echo "awake: macOS 専用です" >&2
    return 1
  fi

  local label="com.dotfiles.awake"
  local action="${1:-status}"
  local hours="${2:-}"
  local pid
  local -a args

  case "$action" in
    on)
      if (( $# > 2 )) || [[ -n "$hours" && "$hours" != <1-168> ]]; then
        echo "使い方: awake on [時間: 1〜168 の整数]" >&2
        return 1
      fi
      args=(-i)
      [[ -n "$hours" ]] && args+=(-t "$(( hours * 3600 ))")
      # 既存のタイマーは解除して、新しい指定で開始する。
      if /bin/launchctl list "$label" >/dev/null 2>&1; then
        /bin/launchctl remove "$label" || return 1
      fi
      # submit は終了したプロセスを再起動するため、時間切れ時にジョブ自身を解除する。
      /bin/launchctl submit -l "$label" -- /bin/sh -c \
        '/usr/bin/caffeinate "$@"; /bin/launchctl remove com.dotfiles.awake' \
        awake "${args[@]}" || return 1
      if [[ -n "$hours" ]]; then
        echo "スリープ防止を開始: ${hours}時間"
      else
        echo "スリープ防止を開始: 手動停止まで"
      fi
      echo "画面の消灯・ロックは可能です。解除: awake off"
      ;;
    off | status)
      if (( $# > 1 )); then
        echo "使い方: awake $action" >&2
        return 1
      fi
      if [[ "$action" == off ]]; then
        if /bin/launchctl list "$label" >/dev/null 2>&1; then
          /bin/launchctl remove "$label" || return 1
        fi
        echo "awake のスリープ防止は停止中です"
      else
        pid=$(/bin/launchctl list | awk -v label="$label" '$3 == label && $1 != "-" { print $1 }')
        if [[ -n "$pid" ]]; then
          echo "awake のスリープ防止は有効です (PID: $pid)"
        else
          echo "awake のスリープ防止は停止中です"
        fi
      fi
      ;;
    *)
      echo "使い方: awake on [時間] | off | status" >&2
      return 1
      ;;
  esac
}
