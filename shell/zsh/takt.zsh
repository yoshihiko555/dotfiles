# ============================================
# takt account switching
# ============================================

# 素の `takt` は Claude・Codex とも個人アカウントで動く。
# `takts` は起動時に Claude・Codex それぞれのアカウントを fzf で選んで takt を起動する。
#   会社 Claude: CLAUDE_CONFIG_DIR=~/.claude-work（ccw と同じ）
#   会社 Codex:  CODEX_HOME=~/.codex-work（cxw と同じ。_codex_work_env は codex.zsh）
#
# takt は provider の子プロセスへ process.env をそのまま渡すため、環境変数だけで切り替わる。
# 2 つは別の変数なので「Claude は会社・Codex は個人」のような組み合わせもできる。
# 同じ provider の中でアカウントを混在させることはできない。

# daemon の環境（ps -E の出力）と、いまのシェルで変数の値が違えば成功を返す。未設定は空文字として比べる。
_takts_env_differs() {
  local daemon_env="$1" name="$2" theirs=""
  if [[ "$daemon_env" == *" ${name}="* ]]; then
    theirs="${${daemon_env#* ${name}=}%% *}"
  fi
  [[ "$theirs" != "${(P)name}" ]]
}

takts() (
  if [[ ! -t 0 || ! -t 1 ]]; then
    echo "takts: 端末から起動してください（アカウントを対話で選ぶため）" >&2
    return 1
  fi
  if ! command -v fzf >/dev/null 2>&1; then
    echo "takts: fzf が見つからない" >&2
    return 1
  fi

  local choice
  choice="$(print -rl -- \
    $'personal\tpersonal\tClaude: 個人 / Codex: 個人' \
    $'work\twork\tClaude: 会社 / Codex: 会社' \
    $'work\tpersonal\tClaude: 会社 / Codex: 個人' \
    $'personal\twork\tClaude: 個人 / Codex: 会社' |
    fzf --height=~10 --prompt='takt> ' --delimiter=$'\t' --with-nth=3)" || return
  local -a fields=("${(@ps:\t:)choice}")

  # 個人を選んだときも変数を外す。ccw などから継承した値で会社側に寄らないようにする。
  if [[ "${fields[1]}" == work ]]; then
    local work_config="${CLAUDE_WORK_CONFIG_DIR:-$HOME/.claude-work}"
    mkdir -p "$work_config"
    export CLAUDE_CONFIG_DIR="$work_config"
  else
    unset CLAUDE_CONFIG_DIR
  fi
  if [[ "${fields[2]}" == work ]]; then
    _codex_work_env takts || return 1
  else
    unset CODEX_HOME
  fi

  # manager / director は ~/.takt につき 1 つの daemon で動き、daemon は起動した側の環境を持ち続ける。
  # 動いている daemon は環境が違っても再利用されるため、選択と食い違うときは止めて知らせる。
  # 実行中のタスクがありうるので daemon は自動で止めない。
  if [[ "$1" == (manager|director) ]]; then
    local pid daemon_env
    for pid in $(pgrep -f takt/dist/app/daemon/index.js); do
      daemon_env="$(ps -wwE -o command= -p "$pid" 2>/dev/null)"
      # 環境を読めないと未設定（個人）と区別できないため、判定せずに止める。
      if [[ "$daemon_env" != *" PATH="* ]]; then
        echo "takts: 動いている daemon（pid $pid）のアカウントを確認できません。" >&2
        echo "takts: 実行中のタスクが無いことを確かめ、takt daemon stop で止めてから起動し直してください" >&2
        return 1
      fi
      if _takts_env_differs "$daemon_env" CLAUDE_CONFIG_DIR ||
        _takts_env_differs "$daemon_env" CODEX_HOME; then
        echo "takts: 別のアカウントで動いている daemon があります（pid $pid）。" >&2
        echo "takts: 実行中のタスクが無いことを確かめ、takt daemon stop で止めてから起動し直してください" >&2
        return 1
      fi
    done
  fi

  echo "takts: ${fields[3]}" >&2
  command takt "$@"
)