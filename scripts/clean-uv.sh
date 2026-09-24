#!/bin/bash
# uv キャッシュから到達不能なエントリ（古い uvx 一時環境など）を prune するスクリプト
# claude-mem の worker が uvx で常駐させる chroma-mcp がキャッシュのロックを握るため、
# worker を止めてから prune し、終了時に起動し直す。--force は使わない
# 使い方: bash scripts/clean-uv.sh [--dry-run] [--allow-processing]
set -euo pipefail

DRY_RUN=false
ALLOW_PROCESSING=false
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    --allow-processing) ALLOW_PROCESSING=true ;;
    *)
      echo "不明な引数: $arg" >&2
      exit 2
      ;;
  esac
done

if [[ "$DRY_RUN" == true ]]; then
  echo "[dry-run] 削除は実行しません"
  echo ""
fi

CACHE_DIR=$(uv cache dir)
MEM_DB="$HOME/.claude-mem/claude-mem.db"
PLUGIN_CACHE="$HOME/.claude/plugins/cache/thedotmack/claude-mem"
BUN=$(command -v bun || echo "$HOME/.bun/bin/bun")

free_space() {
  df -h "$CACHE_DIR" | awk 'NR == 2 {print $4}'
}

uv_pids() {
  pgrep -x 'uvx?' || true
}

# hooks.json と同じく、.orphaned_at の付いた旧版を除いた最新版の worker を使う
latest_worker_script() {
  local dir latest
  latest=$(
    for dir in "$PLUGIN_CACHE"/[0-9]*/; do
      [[ -d "$dir" && ! -e "${dir}.orphaned_at" ]] && basename "$dir"
    done | sort -V | tail -1
  )
  [[ -n "$latest" ]] && echo "$PLUGIN_CACHE/$latest/scripts/worker-service.cjs"
}

worker_script=$(latest_worker_script || true)
worker_pid=""
if [[ -n "$worker_script" && -x "$BUN" ]]; then
  status=$("$BUN" "$worker_script" status 2>/dev/null || true)
  worker_pid=$(awk '$1 == "PID:" {print $2}' <<<"$status")
fi

processing=0
if [[ -f "$MEM_DB" ]] && command -v sqlite3 >/dev/null; then
  processing=$(sqlite3 -readonly "$MEM_DB" "select count(*) from pending_messages where status = 'processing';" 2>/dev/null || echo 0)
fi

# worker の子として動く uv（chroma-mcp）と、それ以外の uv プロセスを分ける
chroma_pids=()
foreign_pids=()
for pid in $(uv_pids); do
  if [[ -n "$worker_pid" && "$(ps -o ppid= -p "$pid" | tr -d ' ')" == "$worker_pid" ]]; then
    chroma_pids+=("$pid")
  else
    foreign_pids+=("$pid")
  fi
done

echo "=== uv キャッシュ クリーンアップ ==="
echo ""
echo "[uv] $(du -sh "$CACHE_DIR" 2>/dev/null | awk '{print $1}')（ディスク空き $(free_space)）"
if [[ -n "$worker_pid" ]]; then
  echo "[claude-mem] worker PID $worker_pid / chroma-mcp ${#chroma_pids[@]} 件 / 処理中の記録 $processing 件"
else
  echo "[claude-mem] worker は停止中"
fi
if [[ ${#foreign_pids[@]} -gt 0 ]]; then
  echo "[他の uv プロセス] キャッシュを使用中:"
  for pid in "${foreign_pids[@]}"; do
    echo "  $(ps -o pid=,command= -p "$pid" | cut -c1-150)"
  done
fi

if [[ "$DRY_RUN" == true ]]; then
  echo ""
  if [[ ${#foreign_pids[@]} -gt 0 ]]; then
    echo "-> 他の uv プロセスが終わるまで実行できません"
  elif [[ "$processing" -gt 0 ]]; then
    echo "-> 処理中の記録があるため、落ち着いてから実行してください（強行は --allow-processing）"
  else
    echo "-> worker 停止 → uv cache prune → worker 再起動 を実行できます"
  fi
  echo ""
  echo "実行するには: bash scripts/clean-uv.sh"
  exit 0
fi

if [[ ${#foreign_pids[@]} -gt 0 ]]; then
  echo "-> 他の uv プロセスがキャッシュを使用中のため中止"
  exit 1
fi

restart_worker() {
  echo ""
  echo "claude-mem の worker を起動..."
  "$BUN" "$(latest_worker_script)" start || echo "起動に失敗しました。次の Claude Code 起動時に自動で起動します"
}

if [[ -n "$worker_pid" ]]; then
  if [[ "$processing" -gt 0 && "$ALLOW_PROCESSING" != true ]]; then
    echo "-> claude-mem が記録を $processing 件処理中のため中止（強行は --allow-processing）"
    exit 1
  fi
  echo ""
  echo "claude-mem の worker を停止..."
  "$BUN" "$worker_script" stop
  trap restart_worker EXIT

  for pid in ${chroma_pids[@]+"${chroma_pids[@]}"}; do
    for _ in $(seq 20); do
      kill -0 "$pid" 2>/dev/null || break
      sleep 1
    done
    if kill -0 "$pid" 2>/dev/null; then
      echo "-> chroma-mcp (PID $pid) が終了しないため中止"
      exit 1
    fi
  done
fi

# 停止中に別セッションの hook が worker を起こした場合などに備えて再確認する
if [[ -n "$(uv_pids)" ]]; then
  echo "-> uv プロセスが再び起動したため中止"
  exit 1
fi

echo ""
uv cache prune

echo ""
echo "クリーンアップ後:"
echo "  uv: $(du -sh "$CACHE_DIR" 2>/dev/null | awk '{print $1}')（ディスク空き $(free_space)）"
