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

# Claude Code のハーネスを CLIProxyAPI (localhost:8317) に向けて、
# ChatGPT 有料プランの Codex 枠で GPT-5.6 系モデルを使う。
# 前提:
#   brew install cliproxyapi
#   cliproxyapi --codex-login          # ChatGPT OAuth (初回のみ)
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
  ANTHROPIC_BASE_URL="$CLIPROXY_URL" \
  ANTHROPIC_AUTH_TOKEN="$key" \
  ANTHROPIC_DEFAULT_OPUS_MODEL=gpt-5.6-sol \
  ANTHROPIC_DEFAULT_SONNET_MODEL=gpt-5.6-terra \
  ANTHROPIC_DEFAULT_HAIKU_MODEL=gpt-5.6-luna \
  command claude --model gpt-5.6-sol "$@"
}
