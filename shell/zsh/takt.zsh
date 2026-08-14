# ============================================
# takt account switching
# ============================================

# 通常の `takt` は個人アカウントのまま使う。
# 会社アカウントは `taktw` で、ccw と同じ ~/.claude-work を使う。
#
# takt は claude CLI を子プロセスとして spawn する際に process.env を
# そのまま継承するため、CLAUDE_CONFIG_DIR を渡せば Claude 側のステップだけ
# 会社アカウントに切り替わる。codex / opencode は別の認証情報を使うので影響を受けない。
#
# 注意: 環境変数はプロセス単位で効くため、同一実行内で
# 「計画は会社・実装は個人」のような Claude アカウントの混在はできない。

taktw() {
  local work_config="${CLAUDE_WORK_CONFIG_DIR:-$HOME/.claude-work}"
  mkdir -p "$work_config"
  CLAUDE_CONFIG_DIR="$work_config" command takt "$@"
}
