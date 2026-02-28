# ============================================
# Zsh Configuration
# ============================================

# --------------------------------------------
# 1. Zsh Options
# --------------------------------------------
setopt AUTO_CD              # ディレクトリ名だけでcd
setopt AUTO_PUSHD           # cd時に自動でpushd
setopt PUSHD_IGNORE_DUPS    # pushdで重複を無視
setopt CORRECT              # コマンドのスペルミス訂正
setopt NO_BEEP              # ビープ音を無効化

# --------------------------------------------
# 2. History Settings
# --------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS     # 重複コマンドを無視
setopt HIST_IGNORE_SPACE    # スペース始まりは記録しない
setopt SHARE_HISTORY        # 複数ターミナルで履歴共有
setopt APPEND_HISTORY       # 履歴を追記

# --------------------------------------------
# 3. Tool Initialization
# --------------------------------------------
# mise は .zshenv で activate 済み
eval "$(zoxide init zsh)"
eval "$(sheldon source)"

# Starship prompt
export STARSHIP_CONFIG=~/.config/starship/starship.toml
eval "$(starship init zsh)"

# --------------------------------------------
# 4. Aliases
# --------------------------------------------
source ~/.zsh/aliases.zsh

# --------------------------------------------
# 5. Functions
# --------------------------------------------
# カスタムコマンド一覧を表示
cheat() {
  cat <<'HELP'
── General ─────────────────────────────────
  ll        ls -lah
  la        ls -A
  ..        cd ..  /  ...  cd ../..  /  ....  cd ../../..
  mkdir     mkdir -p (自動で親ディレクトリ作成)
  rm/cp/mv  確認付き (-i)

── Git ─────────────────────────────────────
  g         git
  gs        git status       ga   git add
  gc        git commit       gp   git push
  gl        git log (10件)   gd   git diff
  gb        git branch       gco  git checkout
  gsw       git switch       lg   lazygit

── Docker ──────────────────────────────────
  d         docker           dc   docker compose
  dps       docker ps        dpsa docker ps -a
  conin     docker exec -it

── Dev ─────────────────────────────────────
  v         nvim             c    clear
  h         history          t    tmux
  cc        claude           cx   codex
  gm        gemini
  code      code .

── Digital Garden ──────────────────────────
  trend     今日のトレンドメモを開く
  daily     daily ノート一覧
  weekly    weekly クリッピング一覧

── Tmux ────────────────────────────────────
  t         tmux               ta   attach
  tl        list-sessions      td   detach
  tn        new-session
  tss       fzf でセッション切り替え
  tk        fzf でセッション kill
  tp        ghq プロジェクトでセッション作成
  -s NAME   セッション名を付けて作成  (tn -s work)
  -t NAME   対象セッションを指定      (ta -t work)

── Functions (fzf) ─────────────────────────
  repo      ghq リポジトリに移動
  fe        ファイル検索 → nvim で開く
  fh        コマンド履歴検索
  fb        git ブランチ切り替え
  fkill     プロセスを選んで kill
  dex       docker コンテナに入る
  dcf       compose ファイルを選んで docker compose 実行
  mdopen    Markdown を選んで Dia で開く

── Functions (util) ────────────────────────
  mkcd DIR  ディレクトリ作成して cd
  port NUM  ポート使用プロセス確認
  cc_interrupt ... 中断証跡を記録/確認 (start|end|open|last)
  trust ... Codex trust を add/rm/list/audit
  cheat     このヘルプを表示
HELP
}

# fzf でMarkdownを選んでブラウザで開く
mdopen() {
  local dir="${1:-.}"
  dir="${dir%/}"
  local file target rc

  if [[ ! -d "$dir" ]]; then
    echo "ディレクトリが見つかりません: $dir"
    return 1
  fi

  file=$(cd "$dir" && find . -name "*.md" -type f | sed 's|^\./||' | sort -r \
    | fzf --preview 'head -40 -- {}')
  rc=$?
  [[ $rc -ne 0 ]] && return "$rc"
  [[ -z "$file" ]] && return 0

  target="$dir/$file"
  if command -v open >/dev/null 2>&1; then
    if open -Ra "Dia" >/dev/null 2>&1; then
      open -a "Dia" "$target"
    else
      open "$target"
    fi
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$target" >/dev/null 2>&1
  else
    echo "open/xdg-open が見つかりません: $target"
    return 1
  fi
}

# ディレクトリ作成してcd
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# ポート使用プロセス確認
port() {
  if [[ -z "$1" ]]; then
    echo "Usage: port <port_number>"
    echo "Example: port 3000"
    return 1
  fi
  lsof -i :"$1"
}

# Codex trust 設定を操作
trust() {
  local repo_root="$HOME/ghq/github.com/yoshihiko555/dotfiles"
  local repo_config="$HOME/ghq/github.com/yoshihiko555/dotfiles/codex/.codex/config.toml"
  local home_config="$HOME/.codex/config.toml"
  local manager="$repo_root/scripts/codex-trust-manage.sh"
  local auditor="$repo_root/scripts/codex-trust-audit.sh"
  local config="${CODEX_CONFIG_PATH:-}"
  local cmd="${1:-}"
  local input_path level

  if [[ -z "$config" ]]; then
    if [[ -f "$repo_config" ]]; then
      config="$repo_config"
    else
      config="$home_config"
    fi
  fi

  if [[ ! -f "$config" ]]; then
    echo "config が見つかりません: $config"
    return 1
  fi

  if [[ ! -x "$manager" ]]; then
    echo "trust 管理スクリプトが見つかりません: $manager"
    return 1
  fi

  case "$cmd" in
    add)
      input_path="${2:-$PWD}"
      level="${3:-trusted}"
      CODEX_CONFIG_PATH="$config" bash "$manager" add "$input_path" "$level"
      ;;
    rm)
      input_path="${2:-$PWD}"
      CODEX_CONFIG_PATH="$config" bash "$manager" rm "$input_path"
      ;;
    list)
      CODEX_CONFIG_PATH="$config" bash "$manager" list
      ;;
    audit)
      CODEX_CONFIG_PATH="$config" bash "$auditor"
      ;;
    where)
      echo "$config"
      ;;
    *)
      cat <<'HELP'
Usage:
  trust add [path] [trusted|untrusted]
  trust rm [path]
  trust list
  trust audit
  trust where
HELP
      return 1
      ;;
  esac
}

# fzf + tmux セッション切り替え/作成
tss() {
  if ! command tmux list-sessions &>/dev/null; then
    command tmux new-session
    return
  fi
  local session
  session=$(command tmux list-sessions -F '#{session_name}: #{session_windows} windows (#{session_attached} attached)' \
    | fzf --header='Switch session (Ctrl-C to cancel)' \
    | cut -d: -f1)
  if [[ -n "$session" ]]; then
    if [[ -n "$TMUX" ]]; then
      command tmux switch-client -t "$session"
    else
      command tmux attach-session -t "$session"
    fi
  fi
}

# fzf + tmux セッションを選んで kill
tk() {
  local sessions
  sessions=$(command tmux list-sessions -F '#{session_name}: #{session_windows} windows' 2>/dev/null)
  if [[ -z "$sessions" ]]; then
    echo "No tmux sessions."
    return 1
  fi
  local selected
  selected=$(echo "$sessions" | fzf -m --header='Kill session (Tab for multi-select)' | cut -d: -f1)
  if [[ -n "$selected" ]]; then
    echo "$selected" | while read -r s; do
      command tmux kill-session -t "$s" && echo "Killed: $s"
    done
  fi
}

# プロジェクトディレクトリで tmux セッション作成
tp() {
  local selected name
  selected=$(ghq list | fzf --delimiter=/ --with-nth=2.. --preview 'ls -la "$(ghq root)/{}"' --header='Create tmux session for project')
  if [[ -n "$selected" ]]; then
    name=$(basename "$selected")
    local dir="$(ghq root)/$selected"
    if command tmux has-session -t "=$name" 2>/dev/null; then
      if [[ -n "$TMUX" ]]; then
        command tmux switch-client -t "=$name"
      else
        command tmux attach-session -t "=$name"
      fi
    else
      if [[ -n "$TMUX" ]]; then
        command tmux new-session -d -s "$name" -c "$dir" && command tmux switch-client -t "=$name"
      else
        command tmux new-session -s "$name" -c "$dir"
      fi
    fi
  fi
}

# ghq + fzf でリポジトリに移動
repo() {
  local selected
  selected=$(ghq list | fzf --delimiter=/ --with-nth=2.. --preview 'ls -la "$(ghq root)/{}"')
  [[ -n "$selected" ]] && cd "$(ghq root)/$selected"
}

# fzf + コマンド履歴検索
fh() {
  local selected
  selected=$(history -n 1 | fzf --tac --no-sort)
  [[ -n "$selected" ]] && print -z "$selected"
}

# fzf + git ブランチ切り替え
fb() {
  local branch
  branch=$(git branch -a | sed 's/^..//' | sed 's|remotes/origin/||' | sort -u | fzf)
  [[ -n "$branch" ]] && git switch "$branch" 2>/dev/null || git switch -c "$branch"
}

# fzf + プロセスキル
fkill() {
  local pid
  pid=$(ps aux | sed 1d | fzf -m | awk '{print $2}')
  [[ -n "$pid" ]] && echo "$pid" | xargs kill -9
}

# fzf + ファイル検索して nvim で開く
fe() {
  local file
  file=$(find . -type f 2>/dev/null | fzf --preview 'head -100 -- {}')
  [[ -n "$file" ]] && nvim "$file"
}

# fzf + docker コンテナに入る
dex() {
  local cid
  cid=$(docker ps --format '{{.ID}}\t{{.Names}}\t{{.Image}}' | fzf | awk '{print $1}')
  [[ -n "$cid" ]] && docker exec -it "$cid" /bin/sh
}

# docker compose 用ファイル候補を列挙
_dcf_list_compose_files() {
  local root="$1"

  if command -v fd >/dev/null 2>&1; then
    fd -a -t f -H -d 8 \
      -E .git -E node_modules -E .next -E dist -E build -E target -E .venv \
      -g 'compose.yml' -g 'compose.yaml' \
      -g 'docker-compose.yml' -g 'docker-compose.yaml' \
      -g 'docker-compose.*.yml' -g 'docker-compose.*.yaml' \
      . "$root"
  else
    find "$root" -maxdepth 8 \
      \( -name .git -o -name node_modules -o -name .next -o -name dist -o -name build -o -name target -o -name .venv \) -prune \
      -o -type f \
      \( -name 'compose.yml' -o -name 'compose.yaml' -o -name 'docker-compose.yml' -o -name 'docker-compose.yaml' -o -name 'docker-compose.*.yml' -o -name 'docker-compose.*.yaml' \) \
      -print
  fi
}

# fzf で compose ファイルを選択して docker compose 実行
dcf() {
  local ghq_root current_repo root compose_file rel_path display_path selected compose_dir
  local -a roots args

  if ! command -v docker >/dev/null 2>&1; then
    echo "docker が見つかりません"
    return 1
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    echo "fzf が見つかりません"
    return 1
  fi

  current_repo="$(git rev-parse --show-toplevel 2>/dev/null)"
  [[ -n "$current_repo" && -d "$current_repo" ]] && roots+=("$current_repo")

  if command -v ghq >/dev/null 2>&1; then
    ghq_root="$(ghq root 2>/dev/null)"
    if [[ -n "$ghq_root" && -d "$ghq_root" && "$ghq_root" != "$current_repo" ]]; then
      roots+=("$ghq_root")
    fi
  fi

  if [[ ${#roots[@]} -eq 0 ]]; then
    echo "探索対象が見つかりません (ghq root または git リポジトリ内で実行してください)"
    return 1
  fi

  selected="$(
    for root in "${roots[@]}"; do
      _dcf_list_compose_files "$root" 2>/dev/null | while IFS= read -r compose_file; do
        rel_path="${compose_file#$root/}"
        display_path="$rel_path"

        # ghq 配下は "host/" を落として見やすくする
        if [[ -n "$ghq_root" && "$root" == "$ghq_root" ]]; then
          [[ "$display_path" == */* ]] && display_path="${display_path#*/}"
        fi

        printf '%s\t%s\n' "$display_path" "$compose_file"
      done
    done \
      | awk -F'\t' '!seen[$2]++' \
      | sort \
      | fzf \
        --delimiter=$'\t' \
        --with-nth=1 \
        --header='compose ファイルを選択 (Enter: 実行 / Esc: キャンセル)' \
        --preview 'sed -n "1,140p" {2}' \
        --preview-window=right:60% \
      | cut -f2
  )"

  [[ -z "$selected" ]] && return 0

  args=("$@")
  [[ ${#args[@]} -eq 0 ]] && args=(ps)

  compose_dir="$(dirname "$selected")"
  (
    cd "$compose_dir" || exit 1
    docker compose -f "$selected" "${args[@]}"
  )
}

# --------------------------------------------
# 6. Local Config (machine-specific)
# --------------------------------------------
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# bun completions
[ -s "/Users/yoshihiko/.bun/_bun" ] && source "/Users/yoshihiko/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

. "$HOME/.local/bin/env"

alias claude-mem='bun "/Users/yoshihiko/.claude/plugins/marketplaces/thedotmack/plugin/scripts/worker-service.cjs"'


# ---- Claude Code interruption evidence logger (zshrc) ----
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
# ---- end ----
