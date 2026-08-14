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

ccx() {
  local key
  key="$(sed -n '/^api-keys:/{n;s/.*"\(.*\)".*/\1/p;}' "$CLIPROXY_CONF" 2>/dev/null)"
  if [[ -z "$key" ]]; then
    echo "ccx: $CLIPROXY_CONF から api-keys を読めない (brew install cliproxyapi 済み?)" >&2
    return 1
  fi
  if ! curl -sf -m 2 -o /dev/null "$CLIPROXY_URL/v1/models" -H "Authorization: Bearer $key"; then
    echo "ccx: CLIProxyAPI に接続できない (brew services start cliproxyapi)" >&2
    return 1
  fi
  # /model ピッカーは gateway model discovery で claude* 始まりの ID だけ自動追加される。
  # GPT-5.6 系は cliproxyapi.conf の oauth-model-alias で claude-gpt-5.6-* に fork 公開
  # してあるため、Claude 系 (opus/sonnet/haiku) と GPT 系 (sol/terra/luna) が両方並ぶ。
  ANTHROPIC_BASE_URL="$CLIPROXY_URL" \
  ANTHROPIC_AUTH_TOKEN="$key" \
  CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1 \
  CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1 \
  CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=3 \
  ENABLE_TOOL_SEARCH=false \
  command claude "$@"
}
