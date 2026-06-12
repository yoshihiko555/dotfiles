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
