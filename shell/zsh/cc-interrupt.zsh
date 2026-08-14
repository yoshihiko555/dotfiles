# ============================================
# Claude Code Interruption Evidence Logger
# ============================================

# 対話シェルだけで定義したい場合（推奨）
[[ -o interactive ]] || return

export CC_EVIDENCE_LEGACY_DIR="${HOME}/claude_code_evidence"
if [[ -z "${CC_EVIDENCE_DIR:-}" || "${CC_EVIDENCE_DIR}" == "${CC_EVIDENCE_LEGACY_DIR}" ]]; then
  export CC_EVIDENCE_DIR="${HOME}/Library/Application Support/claude_code_evidence"
fi

# 旧保存先(~/claude_code_evidence)から新保存先へ一度だけ移行
if [[ "${CC_EVIDENCE_DIR}" != "${CC_EVIDENCE_LEGACY_DIR}" && -d "${CC_EVIDENCE_LEGACY_DIR}" && ! -d "${CC_EVIDENCE_DIR}" ]]; then
  mkdir -p "$(dirname "${CC_EVIDENCE_DIR}")"
  mv "${CC_EVIDENCE_LEGACY_DIR}" "${CC_EVIDENCE_DIR}" 2>/dev/null || true
fi

export CC_EVIDENCE_STATE="${CC_EVIDENCE_DIR}/_state.json"
export CC_EVIDENCE_LOG="${CC_EVIDENCE_DIR}/incidents.jsonl"

_cc_now_iso() { date "+%Y-%m-%dT%H:%M:%S%z"; }
_cc_now_id()  { date "+%Y%m%d-%H%M%S"; }

_cc_take_usage_screenshot() {
  local out="$1"
  mkdir -p "${CC_EVIDENCE_DIR}"

  echo "Claude Codeで /usage を表示した状態にして Enter → 次にウィンドウをクリックして撮影します"
  read -r _

  if command -v screencapture >/dev/null 2>&1; then
    # -w: クリックしたウィンドウを撮影（macOS）
    screencapture -w "${out}"
  else
    echo "ERROR: screencapture が見つかりません（macOS以外では別実装が必要）"
    return 1
  fi
  echo "Saved: ${out}"
}

_cc_state_read() {
  /usr/bin/python3 - <<'PY' "${CC_EVIDENCE_STATE}"
import json, sys, os
p=sys.argv[1]
if not os.path.exists(p):
  print("{}")
  raise SystemExit(0)
print(open(p, encoding="utf-8").read())
PY
}

_cc_state_write() {
  local json="$1"
  /usr/bin/python3 - <<'PY' "${CC_EVIDENCE_STATE}" "${json}"
import sys, os
p=sys.argv[1]; data=sys.argv[2]
os.makedirs(os.path.dirname(p), exist_ok=True)
with open(p, "w", encoding="utf-8") as f:
  f.write(data)
PY
}

_cc_log_append() {
  local json="$1"
  mkdir -p "${CC_EVIDENCE_DIR}"
  print -r -- "${json}" >> "${CC_EVIDENCE_LOG}"
}

_cc_minutes_diff() {
  local start="$1" end="$2"
  /usr/bin/python3 - <<'PY' "${start}" "${end}"
from datetime import datetime
import sys
fmt="%Y-%m-%dT%H:%M:%S%z"
s=datetime.strptime(sys.argv[1], fmt)
e=datetime.strptime(sys.argv[2], fmt)
mins=(e-s).total_seconds()/60
print(round(mins, 1))
PY
}

cc_interrupt() {
  local mode="${1:-help}"
  mkdir -p "${CC_EVIDENCE_DIR}"

  case "${mode}" in
    start)
      local id="$(_cc_now_id)"
      local ts="$(_cc_now_iso)"
      local ss="${CC_EVIDENCE_DIR}/${id}_usage_start.png"

      _cc_take_usage_screenshot "${ss}" || return 1

      _cc_log_append "$(/usr/bin/python3 - <<PY
import json
print(json.dumps({
  "id": "${id}",
  "event": "start",
  "ts": "${ts}",
  "usage_screenshot": "${ss}",
}, ensure_ascii=False))
PY
)"
      _cc_state_write "$(/usr/bin/python3 - <<PY
import json
print(json.dumps({
  "id": "${id}",
  "start_ts": "${ts}",
  "start_screenshot": "${ss}"
}, ensure_ascii=False))
PY
)"
      echo "START logged: id=${id} ts=${ts}"
      ;;

    end)
      local ts="$(_cc_now_iso)"
      local state="$(_cc_state_read)"
      local id start_ts
      id="$(print -r -- "${state}" | /usr/bin/python3 -c 'import json,sys; print(json.loads(sys.stdin.read() or "{}").get("id",""))')"
      start_ts="$(print -r -- "${state}" | /usr/bin/python3 -c 'import json,sys; print(json.loads(sys.stdin.read() or "{}").get("start_ts",""))')"

      if [[ -z "${id}" || -z "${start_ts}" ]]; then
        echo "WARN: start の状態が見つからないため end 単体で記録します（start忘れの可能性）"
        id="$(_cc_now_id)"
        start_ts="${ts}"
      fi

      local ss="${CC_EVIDENCE_DIR}/${id}_usage_end.png"
      _cc_take_usage_screenshot "${ss}" || return 1

      local duration_min="$(_cc_minutes_diff "${start_ts}" "${ts}")"

      _cc_log_append "$(/usr/bin/python3 - <<PY
import json
print(json.dumps({
  "id": "${id}",
  "event": "end",
  "ts": "${ts}",
  "usage_screenshot": "${ss}",
  "duration_min": float("${duration_min}")
}, ensure_ascii=False))
PY
)"
      rm -f "${CC_EVIDENCE_STATE}" 2>/dev/null || true
      echo "END logged: id=${id} ts=${ts} duration_min=${duration_min}"
      ;;

    open)
      # 証跡フォルダを開く（macOS）
      command -v open >/dev/null 2>&1 && open "${CC_EVIDENCE_DIR}"
      echo "${CC_EVIDENCE_DIR}"
      ;;

    last)
      tail -n 5 "${CC_EVIDENCE_LOG}" 2>/dev/null || echo "No log yet: ${CC_EVIDENCE_LOG}"
      ;;

    report)
      if [[ ! -f "${CC_EVIDENCE_LOG}" ]]; then
        echo "No log yet: ${CC_EVIDENCE_LOG}"
        return 0
      fi
      /usr/bin/python3 - <<'PY' "${CC_EVIDENCE_LOG}"
import json
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

log_path = Path(sys.argv[1])
fmt = "%Y-%m-%dT%H:%M:%S%z"

def parse_ts(raw):
  try:
    return datetime.strptime(raw, fmt)
  except Exception:
    return None

records = []
for line in log_path.read_text(encoding="utf-8").splitlines():
  line = line.strip()
  if not line:
    continue
  try:
    records.append(json.loads(line))
  except json.JSONDecodeError:
    continue

if not records:
  print(f"No valid log records: {log_path}")
  raise SystemExit(0)

start_events = [r for r in records if r.get("event") == "start"]
end_events = [r for r in records if r.get("event") == "end"]

start_ids = Counter(r.get("id", "") for r in start_events if r.get("id"))
end_ids = Counter(r.get("id", "") for r in end_events if r.get("id"))
matched = sum(min(start_ids[k], end_ids[k]) for k in start_ids)
open_count = sum(start_ids.values()) - matched
orphan_end = sum(end_ids.values()) - matched

all_ts = [parse_ts(r.get("ts", "")) for r in records]
all_ts = [t for t in all_ts if t is not None]
first_ts = min(all_ts) if all_ts else None
last_ts = max(all_ts) if all_ts else None

elapsed_days = 0
if first_ts and last_ts:
  elapsed_days = (last_ts.date() - first_ts.date()).days + 1

daily_starts = Counter()
for r in start_events:
  t = parse_ts(r.get("ts", ""))
  if t is not None:
    daily_starts[t.strftime("%Y-%m-%d")] += 1

durations = []
for r in end_events:
  v = r.get("duration_min")
  if isinstance(v, (int, float)):
    durations.append(float(v))
  elif isinstance(v, str):
    try:
      durations.append(float(v))
    except ValueError:
      pass

print("=== cc_interrupt report ===")
print(f"ログ: {log_path}")
if first_ts:
  print(f"運用開始: {first_ts.isoformat()}")
if last_ts:
  print(f"最新記録: {last_ts.isoformat()}")
if elapsed_days:
  print(f"経過日数: {elapsed_days}日")
print("")
print(f"中断開始(start): {len(start_events)}件")
print(f"中断終了(end): {len(end_events)}件")
print(f"完了(開始/終了ペア): {matched}件")
print(f"未完了(開始のみ): {open_count}件")
if orphan_end > 0:
  print(f"終了のみ(開始記録なし): {orphan_end}件")

if durations:
  total = round(sum(durations), 1)
  avg = round(total / len(durations), 1)
  print(f"中断時間合計(end記録ベース): {total}分")
  print(f"中断時間平均(end記録ベース): {avg}分")
else:
  print("中断時間合計(end記録ベース): 0分")
  print("中断時間平均(end記録ベース): N/A")

print("")
print("日別中断開始件数(直近7日):")
daily_items = sorted(daily_starts.items())
if not daily_items:
  print("  なし")
else:
  for day, count in daily_items[-7:]:
    print(f"  {day}: {count}件")
PY
      ;;

    help|*)
      cat <<'EOF'
Usage:
  cc_interrupt start   # /usageスクショ(開始) + 開始時刻を記録
  cc_interrupt end     # /usageスクショ(復旧) + 復旧時刻 + 中断時間を記録
  cc_interrupt open    # 証跡フォルダを開く
  cc_interrupt last    # 直近ログ表示
  cc_interrupt report  # 運用開始からの中断集計レポート
Logs:
  $CC_EVIDENCE_LOG
EOF
      ;;
  esac
}
