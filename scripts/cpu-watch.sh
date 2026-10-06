#!/bin/bash
# CPU が張り付いた時点のスナップショットを記録する調査用スクリプト
# 全体のアイドル% を一定間隔で監視し、閾値未満が続いたら上位プロセス・メモリ状況・
# 最も重いユーザープロセスの sample を ~/Library/Logs/cpu-watch/ に残す
# 常駐は LaunchAgent（リポジトリ管理外）で行い、調査が終わったら --uninstall で外す
# 使い方: bash scripts/cpu-watch.sh [--once | --install | --uninstall]
set -euo pipefail

LOG_DIR="${CPU_WATCH_LOG_DIR:-$HOME/Library/Logs/cpu-watch}"
INTERVAL="${CPU_WATCH_INTERVAL:-5}"              # 監視間隔（秒）
IDLE_THRESHOLD="${CPU_WATCH_IDLE_THRESHOLD:-10}" # アイドル% がこれ未満なら高負荷とみなす
CONSECUTIVE="${CPU_WATCH_CONSECUTIVE:-2}"        # 何回連続で高負荷ならスナップショットを取るか
COOLDOWN="${CPU_WATCH_COOLDOWN:-60}"             # スナップショットの最短間隔（秒）
SAMPLE_SECONDS="${CPU_WATCH_SAMPLE_SECONDS:-2}"  # sample の採取時間（秒）
SAMPLE_MIN_CPU="${CPU_WATCH_SAMPLE_MIN_CPU:-50}" # この %CPU 以上のユーザープロセスだけ sample する
HEARTBEAT="${CPU_WATCH_HEARTBEAT:-60}"           # 閾値に関係なく状態を 1 行残す間隔（秒）
RETENTION_DAYS="${CPU_WATCH_RETENTION_DAYS:-14}"

LABEL="com.yoshihiko.cpu-watch"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
ME="$(id -un)"

log_file() {
  echo "$LOG_DIR/$(date +%F).log"
}

prune_old() {
  find "$LOG_DIR" -type f -name '*.log' -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
  find "$LOG_DIR/samples" -type f -mtime +"$RETENTION_DAYS" -delete 2>/dev/null || true
}

# 直近 INTERVAL 秒の平均を "us sy id load1" で返す（iostat の 1 行目は起動時からの平均なので捨てる）
read_cpu() {
  iostat -n0 -w "$INTERVAL" -c 2 | awk 'END { print $1, $2, $3, $4 }'
}

# もたつきが CPU 以外（メモリ圧縮など）由来でも後から時刻で突き合わせられるよう、定期的に状態を残す
heartbeat() {
  local mem
  mem="$(vm_stat | awk -F: '
    /^Pages free/ { free = $2 }
    /^Pages occupied by compressor/ { comp = $2 }
    /^Compressions/ { c = $2 }
    END { printf "free=%dMB comp=%dMB compressions=%d", free * 16 / 1024, comp * 16 / 1024, c }')"
  echo "$(date '+%T') hb: us=$1 sy=$2 id=$3 load1=$4 pressure=$(sysctl -n kern.memorystatus_vm_pressure_level) $mem" >>"$(log_file)"
}

snapshot() {
  local reason="$1" out stamp top_out pids target sample_file
  out="$(log_file)"
  stamp="$(date +%Y%m%d-%H%M%S)"

  # top の 1 回目は %CPU が正しくないため 2 回目のブロックだけ使う
  top_out="$(top -l 2 -s 1 -o cpu -n 25 -stats pid,ppid,user,command,cpu,threads,mem,state 2>/dev/null \
    | awk '/^PID/ { n++ } n == 2')"
  pids="$(echo "$top_out" | awk 'NR > 1 { print $1 }' | paste -sd, -)"

  {
    echo "===== $(date '+%F %T') snapshot ($reason)"
    echo "load: $(sysctl -n vm.loadavg)  pressure_level: $(sysctl -n kern.memorystatus_vm_pressure_level) (1=normal 2=warn 4=critical)"
    echo "disk: $(iostat -d -n1 -w 1 -c 2 | awk 'END { print $1 " KB/t, " $2 " tps, " $3 " MB/s" }')"
    echo "-- memory (page = 16KB)"
    vm_stat | grep -E '^(Pages free|Pages occupied by compressor|Pages stored in compressor|Compressions|Decompressions|Pageins|Swapouts)'
    echo "-- %CPU by command (top 25 processes)"
    echo "$top_out" | awk '
      NR > 1 {
        cmd = ""
        for (i = 4; i <= NF - 4; i++) cmd = cmd (i > 4 ? " " : "") $i
        sum[cmd] += $(NF - 3); cnt[cmd]++
      }
      END { for (c in sum) printf "%7.1f  %s (x%d)\n", sum[c], c, cnt[c] }' | sort -rn | head -10
    echo "-- top processes"
    echo "$top_out"
    echo "-- args"
    ps -o pid=,etime=,args= -p "$pids" 2>/dev/null | cut -c1-250 || true
  } >>"$out"

  # root 所有のプロセス（kernel_task, WindowServer 等）は sudo なしでは sample できない
  target="$(echo "$top_out" | awk -v u="$ME" -v min="$SAMPLE_MIN_CPU" \
    'NR > 1 && $3 == u && $(NF - 3) + 0 >= min { print $1; exit }')"
  if [[ -n "$target" ]]; then
    sample_file="$LOG_DIR/samples/$stamp-$target.txt"
    if sample "$target" "$SAMPLE_SECONDS" -mayDie -file "$sample_file" >/dev/null 2>&1; then
      gzip -f "$sample_file"
      echo "-- sample: samples/$(basename "$sample_file").gz" >>"$out"
    else
      echo "-- sample: PID $target の採取に失敗" >>"$out"
    fi
  fi
  echo "" >>"$out"
}

install_agent() {
  mkdir -p "$LOG_DIR" "$(dirname "$PLIST")"
  cat >"$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$SCRIPT_PATH</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardErrorPath</key>
  <string>$LOG_DIR/stderr.log</string>
</dict>
</plist>
EOF
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST"
  echo "起動しました: ${LABEL}（ログ: ${LOG_DIR}）"
}

uninstall_agent() {
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  rm -f "$PLIST"
  echo "停止・削除しました: ${LABEL}（ログは $LOG_DIR に残っています）"
}

case "${1:-}" in
  --install)
    install_agent
    exit 0
    ;;
  --uninstall)
    uninstall_agent
    exit 0
    ;;
  --once)
    mkdir -p "$LOG_DIR/samples"
    snapshot "手動実行"
    echo "記録しました: $(log_file)"
    exit 0
    ;;
  "") ;;
  *)
    echo "不明な引数: $1" >&2
    exit 2
    ;;
esac

mkdir -p "$LOG_DIR/samples"
prune_old
echo "$(date '+%F %T') start: interval=${INTERVAL}s idle<${IDLE_THRESHOLD}% x${CONSECUTIVE}" >>"$(log_file)"

high=0
last_snap=0
last_hb=0
last_prune="$(date +%s)"
while true; do
  cpu="$(read_cpu)" || {
    sleep "$INTERVAL"
    continue
  }
  read -r us sy id load1 <<<"$cpu"
  case "$id" in
    '' | *[!0-9]*) continue ;;
  esac

  now="$(date +%s)"
  if ((now - last_hb >= HEARTBEAT)); then
    heartbeat "$us" "$sy" "$id" "$load1"
    last_hb="$now"
  fi

  if ((id < IDLE_THRESHOLD)); then
    high=$((high + 1))
    echo "$(date '+%T') high: us=$us sy=$sy id=$id load1=$load1" >>"$(log_file)"
    if ((high >= CONSECUTIVE && now - last_snap >= COOLDOWN)); then
      snapshot "idle ${id}% が ${high} 回連続"
      last_snap="$now"
    fi
  else
    if ((high >= CONSECUTIVE)); then
      echo "$(date '+%T') recovered: 高負荷 ${high} 回（約 $((high * INTERVAL)) 秒）" >>"$(log_file)"
    fi
    high=0
  fi

  if ((now - last_prune >= 86400)); then
    prune_old
    last_prune="$now"
  fi
done
