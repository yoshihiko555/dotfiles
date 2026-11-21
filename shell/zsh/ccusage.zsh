# ============================================
# ccusage の使用量をアカウント別に並べる (ccu)
# ============================================

# ccusage はディレクトリ別の内訳を出さず、複数を渡すと合算する。
# ログのディレクトリを 1 つずつ渡し、個人と仕事の表を別々に出す。
#   ccu                  今月だけ（monthly --last 1 --compact）
#   ccu daily --last 7   引数は `ccusage claude` / `ccusage codex` の後ろにそのまま渡す
#   ccu --breakdown      先頭がオプションなら monthly を補う
#   ccu help             チートシート
# Codex に無いサブコマンド（weekly / blocks / statusline）では Codex の表を飛ばす。
ccu() {
  if [[ "$1" == (help|-h|--help) ]]; then
    _ccu_help
    return 0
  fi
  if (( ! $+commands[ccusage] )); then
    echo "ccu: ccusage が見つからない (config/nix/home/packages.nix を nxs で反映する)" >&2
    return 1
  fi

  local -a args=("$@")
  if (( $# == 0 )); then
    args=(monthly --last 1 --compact)
  elif [[ "$1" == -* ]]; then
    args=(monthly "$@")
  fi

  local rc=0
  _ccu_report "Claude Code・個人" claude CLAUDE_CONFIG_DIR "$HOME/.claude" unset "${args[@]}" || rc=1
  _ccu_report "Claude Code・仕事" claude CLAUDE_CONFIG_DIR "$CLAUDE_WORK_CONFIG_DIR" set "${args[@]}" || rc=1
  _ccu_report "Codex・個人" codex CODEX_HOME "$HOME/.codex" unset "${args[@]}" || rc=1
  _ccu_report "Codex・仕事" codex CODEX_HOME "$CODEX_WORK_HOME" set "${args[@]}" || rc=1
  return $rc
}

# 個人側は変数を外して ccusage の既定の場所を読ませる（セッションから継いだ値に引きずられない）。
_ccu_report() {
  local label=$1 tool=$2 var=$3 dir=$4 mode=$5
  shift 5

  local shown="${dir/#$HOME/~}"
  local heading="== $label (${shown:-未設定}) =="
  if [[ -t 1 ]]; then
    print -r -- $'\n\e[1m'"$heading"$'\e[0m'
  else
    print -r -- $'\n'"$heading"
  fi

  if [[ -z "$dir" || ! -d "$dir" ]]; then
    print -r -- "${shown:-ディレクトリ} が無いので飛ばす"
    return 0
  fi
  if [[ "$tool" == codex && "$1" == (weekly|blocks|statusline) ]]; then
    print -r -- "Codex には $1 が無いので飛ばす"
    return 0
  fi

  local -a env_args
  if [[ "$mode" == unset ]]; then
    env_args=(-u "$var")
  else
    env_args=("$var=$dir")
  fi
  env "${env_args[@]}" ccusage "$tool" "$@"
}

_ccu_help() {
  cat <<'HELP'
ccu: Claude Code・Codex の使用量を、個人と仕事のアカウント別に 4 つの表で出す
     引数はすべて `ccusage claude` / `ccusage codex` の後ろにそのまま渡す

── よく使う形 ──────────────────────────────
  ccu                            今月だけ (monthly --last 1 --compact)
  ccu daily --last 7             直近 7 日
  ccu monthly --last 3 -b        3 か月分をモデル別の金額つきで
  ccu session --last 5 -o desc   直近 5 セッションを新しい順に
  ccu daily -s 20261101 -u 20261115
                                 期間を指定
  ccu --breakdown                先頭がオプションなら monthly を補う
                                 (既定の --last 1 --compact は付かない)

── サブコマンド ────────────────────────────
  daily / monthly / session      Claude・Codex の両方
  weekly / blocks                Claude だけ (Codex の表は飛ばす)

── オプション ──────────────────────────────
  --last N                       直近 N 期間 (daily なら N 日、monthly なら N か月)
  -s / -u YYYYMMDD               期間の始まり / 終わり
  -b, --breakdown                モデル別の金額
  -o desc                        新しい順
  -z Asia/Tokyo                  日付を区切るタイムゾーン
  --compact                      列を減らす (効くのは Claude の表だけ)
  -j, --json                     JSON (見出しが混ざるので jq へは直接流せない)
  -O, --offline                  内蔵の価格表だけ (新しいモデルの金額が抜ける)
  片方だけにあるもの             Codex: --speed / --no-cost   Claude: -m / -d
                                 (無い側の表はエラーになり得る。残りの表は出る)

── 表の順番 ────────────────────────────────
  1. ~/.claude                   Claude Code・個人
  2. $CLAUDE_WORK_CONFIG_DIR     Claude Code・仕事 (既定 ~/.claude-work)
  3. ~/.codex                    Codex・個人
  4. $CODEX_WORK_HOME            Codex・仕事 (既定 ~/.codex-work)
  ディレクトリが無いアカウントは飛ばす。1 つ失敗しても残りは出し、最後に非 0

  ccusage 自体の help: ccusage claude monthly --help / ccusage codex monthly --help
HELP
}
