# ============================================
# pi アカウント切り替え
# ============================================

# 通常の pi は個人用（~/.pi/agent）。会社用の認証・設定・セッションは ~/.pi/agent-work に保存する。
# settings.json の packages は設定ディレクトリ基準の相対パスのため、保存先は個人用と同じ深さに固定する。
piw() (
  local agent_dir="$HOME/.pi/agent-work"
  # settings.json が無いと pi-harness（gate を含む）が読み込まれないまま起動してしまう。
  if [[ ! -f "$agent_dir/settings.json" || ! -f "$agent_dir/pi-harness/gate.json" ]]; then
    echo "piw: 会社用の設定がありません。nix-darwin の switch（nxs）で反映してください" >&2
    return 1
  fi

  # 親シェルの API キーやセッション保存先より、会社用ディレクトリのログインを使う。
  unset OPENAI_API_KEY ANTHROPIC_API_KEY ANTHROPIC_AUTH_TOKEN ANTHROPIC_OAUTH_TOKEN
  unset OPENCODE_API_KEY TYPESAFE_API_KEY PI_CODING_AGENT_SESSION_DIR
  PI_CODING_AGENT_DIR="$agent_dir" pi "$@"
)
