# ============================================
# Codex CLI アカウント切り替え
# ============================================

# 通常の codex / cx は個人用。会社用の認証・設定・履歴は別のホームに保存する。
export CODEX_WORK_HOME="${CODEX_WORK_HOME:-$HOME/.codex-work}"

cxw() (
  local work_home="${CODEX_WORK_HOME:A}"
  if [[ "$work_home" == "${HOME:A}/.codex" ||
    ( -d "$HOME/.codex" && "$work_home" -ef "$HOME/.codex" ) ]]; then
    echo "cxw: CODEX_WORK_HOME に個人用の ~/.codex は指定できません" >&2
    return 1
  fi
  if [[ ! -f "$work_home/config.toml" ]]; then
    echo "cxw: dotfiles で task codex-work-init を実行してください" >&2
    return 1
  fi

  # 親シェルの認証や DB 保存先より、会社用ホームのログインを使う。
  unset CODEX_API_KEY CODEX_ACCESS_TOKEN OPENAI_API_KEY CODEX_SQLITE_HOME
  unset OPENAI_FEDERATION_RULE_ID OPENAI_IDENTITY_TOKEN_FILE OPENAI_WORKLOAD_IDENTITY_CONTEXT
  CODEX_HOME="$work_home" codex "$@"
)
