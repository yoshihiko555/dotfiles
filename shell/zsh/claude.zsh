# ============================================
# Claude Code account switching
# ============================================

# 通常の `cc` / `claude` は個人アカウントのまま使う。
# 会社アカウントは `ccw` で、Git 管理外の ~/.claude-work を使う。

export CLAUDE_WORK_CONFIG_DIR="${CLAUDE_WORK_CONFIG_DIR:-$HOME/.claude-work}"

ccw() {
  mkdir -p "$CLAUDE_WORK_CONFIG_DIR"
  CLAUDE_CONFIG_DIR="$CLAUDE_WORK_CONFIG_DIR" command claude "$@"
}

# ============================================
# subagent 委譲モード (ccf / ccx -f 共通)
# ============================================

# タスク実行を subagent に委譲させるモード。ccf と ccx -f で同じ設定を使うため、
# alias ではなくここに一元化している。
CLAUDE_DELEGATE_SUBAGENT_MODEL="${CLAUDE_DELEGATE_SUBAGENT_MODEL:-claude-sonnet-5}"
CLAUDE_DELEGATE_PROMPT="基本的にタスクや作業の実行は、適切な粒度でsubagentsに実行手順が明確な指示を与えて委譲すること。あなたは全体進行の俯瞰と立案を行う。自己判断による例外は認める"

ccf() {
  CLAUDE_CODE_SUBAGENT_MODEL="$CLAUDE_DELEGATE_SUBAGENT_MODEL" \
  command claude --append-system-prompt "$CLAUDE_DELEGATE_PROMPT" "$@"
}

# ============================================
# Claude Code × Codex (GPT-5.6) via CLIProxyAPI
# ============================================

# Claude Code のハーネスを CLIProxyAPI (localhost:8317) に向ける切替式 (ルートB-2)。
# 起動直後は普段の Claude のまま。`/model gpt-5.6-sol` で Codex 側 (ChatGPT 有料プランの
# Codex 枠) に切り替え、`/model` で Claude に戻せる。
# 前提:
#   brew install cliproxyapi
#   cliproxyapi --codex-login          # ChatGPT OAuth (初回のみ)
#   cliproxyapi --claude-login         # Claude OAuth (初回のみ、Claude モデル中継用)
#   brew services start cliproxyapi    # launchd 常駐
# API キーは cliproxyapi.conf の api-keys から実行時に読む (dotfiles に秘匿値を置かない)。
export CLIPROXY_CONF="${CLIPROXY_CONF:-${HOMEBREW_PREFIX:-/opt/homebrew}/etc/cliproxyapi.conf}"
export CLIPROXY_URL="${CLIPROXY_URL:-http://127.0.0.1:8317}"

# 起動時のモデル。settings.json の既定値 (opus[1m]) はプロキシ側に存在せず
# "unknown provider" になるため、ccx では --model で明示的に上書きする。
# ([1m] の 1M コンテキストはプロキシ経由では使えない)
CLIPROXY_DEFAULT_MODEL="${CLIPROXY_DEFAULT_MODEL:-claude-opus-5}"

#   ccx        通常起動 (~/.claude の設定・skills・plugins はそのまま共有)
#   ccx -f     ccf と同じ subagent 委譲モードをプロキシ経由で使う
ccx() {
  local key delegate=0
  if [[ "$1" == "-f" || "$1" == "--delegate" ]]; then
    delegate=1
    shift
  fi
  key="$(sed -n '/^api-keys:/{n;s/.*"\(.*\)".*/\1/p;}' "$CLIPROXY_CONF" 2>/dev/null)"
  if [[ -z "$key" ]]; then
    echo "ccx: $CLIPROXY_CONF から api-keys を読めない (brew install cliproxyapi 済み?)" >&2
    return 1
  fi
  if ! curl -sf -m 2 -o /dev/null "$CLIPROXY_URL/v1/models" -H "Authorization: Bearer $key"; then
    echo "ccx: CLIProxyAPI に接続できない (brew services start cliproxyapi)" >&2
    return 1
  fi
  local -a extra_env extra_args
  if (( delegate )); then
    extra_env=(CLAUDE_CODE_SUBAGENT_MODEL="$CLAUDE_DELEGATE_SUBAGENT_MODEL")
    extra_args=(--append-system-prompt "$CLAUDE_DELEGATE_PROMPT")
  fi
  # 呼び出し側が --model を渡していなければ既定モデルを補う。
  # --model はセッション内の一時指定なので settings.json を汚さない。
  if [[ " $* " != *" --model "* ]]; then
    extra_args+=(--model "$CLIPROXY_DEFAULT_MODEL")
  fi

  # /model ピッカーは gateway model discovery で claude* 始まりの ID だけ自動追加される。
  # GPT-5.6 系は cliproxyapi.conf の oauth-model-alias で claude-gpt-5.6-* に fork 公開
  # してあるため、Claude 系 (opus/sonnet/haiku) と GPT 系 (sol/terra/luna) が両方並ぶ。
  #
  # 注意: ピッカーで選んだモデルは共有の ~/.claude/settings.json に永続化される。
  # プロキシ専用の ID のまま終了すると、次に素の cc / ccf を起動したときに
  # api.anthropic.com が知らないモデル名になって壊れる。抜ける前に /model で戻すこと。
  env \
    ANTHROPIC_BASE_URL="$CLIPROXY_URL" \
    ANTHROPIC_AUTH_TOKEN="$key" \
    CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1 \
    CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1 \
    CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=3 \
    ENABLE_TOOL_SEARCH=false \
    "${extra_env[@]}" \
    claude "${extra_args[@]}" "$@"
}
