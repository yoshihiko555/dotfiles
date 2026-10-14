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
CLAUDE_DELEGATE_SUBAGENT_MODEL="${CLAUDE_DELEGATE_SUBAGENT_MODEL:-claude-sonnet-5-5}"
CLAUDE_DELEGATE_PROMPT="基本的にタスクや作業の実行は、適切な粒度でsubagentsに実行手順が明確な指示を与えて委譲すること。あなたは全体進行の俯瞰と立案を行う。自己判断による例外は認める"

ccf() {
  CLAUDE_CODE_SUBAGENT_MODEL="$CLAUDE_DELEGATE_SUBAGENT_MODEL" \
  command claude --append-system-prompt "$CLAUDE_DELEGATE_PROMPT" "$@"
}

# ============================================
# Claude Code × Codex (GPT-6) / OpenCode Go via CLIProxyAPI
# ============================================

# Claude Code のハーネスを CLIProxyAPI (localhost:8317) に向ける切替式 (ルートB-2)。
# 起動直後は普段の Claude のまま。`/model gpt-6.1-sol-claude` で Codex 側 (ChatGPT 有料プランの
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
CLIPROXY_DEFAULT_MODEL="${CLIPROXY_DEFAULT_MODEL:-claude-opus-5-5}"

# ccx -f の subagent モデル。OpenCode Go のオープンモデルを subagent に振る試行
# (2026-10-11〜)。プロキシに alias が無い環境では ccf と同じ
# CLAUDE_DELEGATE_SUBAGENT_MODEL へ自動で戻す。
CLIPROXY_DELEGATE_SUBAGENT_MODEL="${CLIPROXY_DELEGATE_SUBAGENT_MODEL:-kimi-k3-claude}"

# バックグラウンド処理 (会話要約など) が使う haiku。プロキシ側で haiku-4-5 を
# ピッカーから除外した (ルーティングからも消える) ため、Claude 側の 5.5 に固定する。
# Claude → Claude の差し替えなので Codex 枠は消費しない。
CLIPROXY_HAIKU_MODEL="${CLIPROXY_HAIKU_MODEL:-claude-haiku-5-5}"

# Claude Code が知らないモデル ID に想定する窓 (既定は 200k で compact が早い)。
# 効くのは claude- で始まらない ID だけ (別名 *-claude、素の gpt-* / go-*)。
# claude-cosmo-* は 200k のまま。Claude 系は 1M のまま変わらない。
# 実際の上限より大きいと compact 前に上流で弾かれるので、Codex の上限 (872k) 以内に置く。
# 素の gpt-5.5 (Codex 経由は 272k) は実窓が小さいので直打ちしない。
CLIPROXY_MAX_CONTEXT_TOKENS="${CLIPROXY_MAX_CONTEXT_TOKENS:-500000}"

#   ccx        通常起動 (~/.claude の設定・skills・plugins はそのまま共有)
#   ccx -f     ccf と同じ subagent 委譲モードをプロキシ経由で使う
ccx() {
  local key delegate=0
  if [[ "$1" == "-f" || "$1" == "--delegate" ]]; then
    delegate=1
    shift
  fi
  # クライアント認証キーは v8 レイアウトの access.api-keys (ルートの api-keys: は上流群)。
  # taskfiles/cliproxy.yml の setup / status と同じ awk。変えるときは 3 箇所揃える。
  key="$(awk '/^access:/{f=1;next} f&&/^[^ #]/{exit} f&&/^  api-keys:/{getline; if (match($0,/"[^"]*"/)) print substr($0,RSTART+1,RLENGTH-2); exit}' "$CLIPROXY_CONF" 2>/dev/null)"
  if [[ -z "$key" ]]; then
    echo "ccx: $CLIPROXY_CONF から api-keys を読めない (brew install cliproxyapi 済み?)" >&2
    return 1
  fi
  local models
  if ! models="$(curl -sf -m 2 "$CLIPROXY_URL/v1/models" -H "Authorization: Bearer $key")"; then
    echo "ccx: CLIProxyAPI に接続できない (brew services start cliproxyapi)" >&2
    return 1
  fi
  local -a extra_env extra_args
  if (( delegate )); then
    local sub="$CLIPROXY_DELEGATE_SUBAGENT_MODEL"
    if [[ "$models" != *"\"$sub\""* ]]; then
      echo "ccx: プロキシに $sub が無いため subagent は $CLAUDE_DELEGATE_SUBAGENT_MODEL を使う" >&2
      sub="$CLAUDE_DELEGATE_SUBAGENT_MODEL"
    fi
    extra_env=(CLAUDE_CODE_SUBAGENT_MODEL="$sub")
    extra_args=(--append-system-prompt "$CLAUDE_DELEGATE_PROMPT")
  fi
  # 呼び出し側が --model を渡していなければ既定モデルを補う。
  # --model はセッション内の一時指定なので settings.json を汚さない。
  if [[ " $* " != *" --model "* ]]; then
    extra_args+=(--model "$CLIPROXY_DEFAULT_MODEL")
  fi

  # /model ピッカーは gateway model discovery で claude/anthropic を含む ID だけ自動追加される。
  # GPT 系は cliproxyapi.conf の oauth.model-alias で gpt-*-claude に fork 公開、
  # OpenCode Go の一部は provider 側 alias で *-claude にしてあるため、
  # Claude 系 (fable/opus/sonnet/haiku) と GPT 6.x、Go (kimi-k3 / glm-5.3) が並ぶ。
  #
  # 注意: ピッカーで選んだモデルは共有の ~/.claude/settings.json に永続化される。
  # プロキシ専用の ID (*-claude / claude-cosmo-*) のまま終了すると、
  # 次に素の cc / ccf を起動したときに api.anthropic.com が知らないモデル名になって
  # 壊れる。抜ける前に /model で戻すこと。
  #
  # CLIProxyAPI は safeguards を中継しないため、auto mode の判定は最初から
  # クライアント側で行わせる (サーバー側判定の不適格通知を出さない)。
  env \
    ANTHROPIC_BASE_URL="$CLIPROXY_URL" \
    ANTHROPIC_AUTH_TOKEN="$key" \
    ANTHROPIC_DEFAULT_HAIKU_MODEL="$CLIPROXY_HAIKU_MODEL" \
    CLAUDE_CODE_AUTO_MODE_SERVER=0 \
    CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1 \
    CLAUDE_CODE_ALWAYS_ENABLE_EFFORT=1 \
    CLAUDE_CODE_MAX_CONTEXT_TOKENS="$CLIPROXY_MAX_CONTEXT_TOKENS" \
    CLAUDE_CODE_MAX_TOOL_USE_CONCURRENCY=3 \
    ENABLE_TOOL_SEARCH=false \
    "${extra_env[@]}" \
    claude "${extra_args[@]}" "$@"
}
