#!/usr/bin/env bash
# ai-inventory: 読み取り専用の収集スクリプト。
# dotfiles / global / project の3スコープにあるAI資産（skill/subagent/command/
# plugin/MCP/hook/context/memory）を棚卸しし、直近30日の利用実績と合わせて
# JSON を stdout に出力する。ファイルの作成・削除・変更は一切行わない
# （このプロセス自身の一時ファイルを除く）。
#
# 使い方: bash collect.sh > inventory.json
# ログ・進捗はすべて stderr に出す（stdout を汚さないため）。

set -uo pipefail

log() { printf '%s\n' "$*" >&2; }

# ---- 前提チェック ----------------------------------------------------
if ! command -v jq >/dev/null 2>&1; then
  log "エラー: jq が見つかりません。'brew install jq' 等でインストールしてください。"
  exit 1
fi

# このシェルの grep は ugrep ラッパーでエラーになることがあるため、
# 収集ロジックでは常に /usr/bin/grep を絶対パスで呼ぶ（設計書の指示）。
GREP=/usr/bin/grep
if [ ! -x "$GREP" ]; then
  log "エラー: /usr/bin/grep が見つかりません。"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
if [ ! -d "$DOTFILES_ROOT/shared/skills" ]; then
  log "エラー: dotfiles ルートの推定に失敗しました ($DOTFILES_ROOT)"
  exit 1
fi
log "dotfiles root: $DOTFILES_ROOT"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

ASSETS_ND="$WORKDIR/assets.ndjson"
WASTE_ND="$WORKDIR/waste.ndjson"
: > "$ASSETS_ND"
: > "$WASTE_ND"

TODAY="$(date +%F)"

# ---- JSON emit ヘルパー -----------------------------------------------
# emit_asset <id> <display_name> <type> <origin> <scope> <targets_csv> <path> \
#            <usage:number|null> <measurable:true|false> <last_modified> <notes>
emit_asset() {
  local id="$1" name="$2" type="$3" origin="$4" scope="$5" targets_csv="$6"
  local path="$7" usage="$8" measurable="$9" last_mod="${10}" notes="${11}"
  local targets_json usage_arg
  if [ -z "$targets_csv" ]; then
    targets_json='[]'
  else
    targets_json="$(printf '%s' "$targets_csv" | tr ',' '\n' | jq -R 'select(length>0)' | jq -s .)"
  fi
  if [ "$usage" = "null" ] || [ -z "$usage" ]; then
    usage_arg='null'
  else
    usage_arg="$usage"
  fi
  jq -n \
    --arg id "$id" --arg display_name "$name" --arg type "$type" --arg origin "$origin" \
    --arg scope "$scope" --argjson targets "$targets_json" --arg path "$path" \
    --argjson usage "$usage_arg" --argjson measurable "$measurable" \
    --arg last_modified "$last_mod" --arg notes "$notes" \
    '{id:$id, display_name:$display_name, type:$type, origin:$origin, scope:$scope,
      targets:$targets, path:$path, usage_this_month:$usage, usage_measurable:$measurable,
      last_modified:$last_modified, notes:$notes}' \
    >> "$ASSETS_ND"
}

# emit_waste <path> <size_mb:number|null> <reason>
emit_waste() {
  local path="$1" size_mb="$2" reason="$3"
  local size_arg
  if [ "$size_mb" = "null" ] || [ -z "$size_mb" ]; then size_arg='null'; else size_arg="$size_mb"; fi
  jq -n --arg path "$path" --argjson size_mb "$size_arg" --arg reason "$reason" \
    '{path:$path, size_mb:$size_mb, reason:$reason}' >> "$WASTE_ND"
}

size_mb_of() {
  # du -sm はディレクトリ/ファイルのMB概算。存在しなければ null 相当の空文字。
  local path="$1"
  if [ -e "$path" ]; then
    du -sm "$path" 2>/dev/null | awk '{print $1}'
  else
    echo ""
  fi
}

get_frontmatter_name() {
  # SKILL.md / agent .md の front matter から name: の値を取り出す。
  # 無ければ空文字を返す（呼び出し側でディレクトリ名/ファイル名にフォールバック）。
  local file="$1"
  awk '
    /^---[[:space:]]*$/ { c++; next }
    c==1 && /^name:[[:space:]]*/ {
      sub(/^name:[[:space:]]*/, "")
      gsub(/^"|"$/, "")
      gsub(/^\x27|\x27$/, "")
      print
      exit
    }
    c>=2 { exit }
  ' "$file" 2>/dev/null
}

git_last_modified() {
  # <repo> <relpath> -> そのファイル/パスの最終コミット日 (YYYY-MM-DD)。
  # コミット履歴が無ければ空文字。
  local repo="$1" relpath="$2"
  git -C "$repo" log -1 --format=%cs -- "$relpath" 2>/dev/null
}

log "=== フェーズA: 利用実績の集計テーブルを構築 ==="

# ---- 利用実績の集計 ----------------------------------------------------
# 対象: ~/.claude/projects/**/*.jsonl のうち直近30日更新分。
# 注意: 一部の過去transcriptには「grep -o '<command-name>...' | uniq -c」の
# ような集計結果テキストが tool_result としてそのまま埋め込まれているケースが
# あり、素朴な文字列一致だと二重カウント（汚染）が発生する。実際の招待タグは
# JSON文字列の先頭付近（"content":"<command-name>... または
# </command-message>\n<command-name>...）にしか出現しないため、その位置に
# アンカーして誤検出を除外する。Skillツール呼び出しは "id":"toolu_..." に
# 続く形でしか本物が出現しないため、同様にアンカーする。
PROJECTS_DIR="$HOME/.claude/projects"
FILELIST="$WORKDIR/jsonl_files.txt"
: > "$FILELIST"
if [ -d "$PROJECTS_DIR" ]; then
  find "$PROJECTS_DIR" -name "*.jsonl" -mtime -30 2>/dev/null > "$FILELIST"
fi
FILE_COUNT="$(wc -l < "$FILELIST" | tr -d ' ')"
log "利用実績の対象ファイル数（直近30日）: $FILE_COUNT"

SKILLTOOL_RAW="$WORKDIR/skilltool_raw.txt"
SLASHCMD_RAW="$WORKDIR/slashcmd_raw.txt"
SUBAGENT_RAW="$WORKDIR/subagent_raw.txt"
MCP_RAW="$WORKDIR/mcp_raw.txt"
: > "$SKILLTOOL_RAW"; : > "$SLASHCMD_RAW"; : > "$SUBAGENT_RAW"; : > "$MCP_RAW"

if [ "$FILE_COUNT" -gt 0 ]; then
  # Skillツール呼び出し: "id":"toolu_...","name":"Skill","input":{"skill":"<name>"
  tr '\n' '\0' < "$FILELIST" | xargs -0 "$GREP" -oh \
    '"id":"toolu_[^"]*","name":"Skill","input":{"skill":"[^"]*"' 2>/dev/null \
    | sed -E 's/.*"skill":"([^"]*)"$/\1/' > "$SKILLTOOL_RAW"

  # スラッシュコマンド: 本物の招待タグのみ（"content":"<command-name>... または
  # </command-message>\n に続く <command-name>...）を対象にする。
  tr '\n' '\0' < "$FILELIST" | xargs -0 "$GREP" -Eoh \
    '("content":"|</command-message>\\n)<command-name>/[^<]*</command-name>' 2>/dev/null \
    | sed -E 's#.*<command-name>/([^<]*)</command-name>#\1#' > "$SLASHCMD_RAW"

  # subagent_type の出現（Task ツールの input）
  tr '\n' '\0' < "$FILELIST" | xargs -0 "$GREP" -oh '"subagent_type":"[^"]*"' 2>/dev/null \
    | sed -E 's/"subagent_type":"([^"]*)"/\1/' > "$SUBAGENT_RAW"

  # MCP ツール呼び出し名 (mcp__<server>__<tool>)
  tr '\n' '\0' < "$FILELIST" | xargs -0 "$GREP" -oh '"name":"mcp__[a-zA-Z0-9_.-]*"' 2>/dev/null \
    | sed -E 's/"name":"(.*)"/\1/' > "$MCP_RAW"
else
  log "警告: 直近30日の transcript が見つかりません。利用実績はすべて0として扱います。"
fi

SKILLTOOL_TSV="$WORKDIR/skilltool_usage.tsv"
SLASHCMD_TSV="$WORKDIR/slashcmd_usage.tsv"
SUBAGENT_TSV="$WORKDIR/subagent_usage.tsv"
sort "$SKILLTOOL_RAW" | uniq -c | awk '{print $2"\t"$1}' > "$SKILLTOOL_TSV"
sort "$SLASHCMD_RAW"  | uniq -c | awk '{print $2"\t"$1}' > "$SLASHCMD_TSV"
sort "$SUBAGENT_RAW"  | uniq -c | awk '{print $2"\t"$1}' > "$SUBAGENT_TSV"

get_tsv_count() {
  local file="$1" name="$2"
  [ -s "$file" ] || { echo 0; return; }
  awk -F'\t' -v n="$name" '$1==n{print $2; f=1} END{if(!f) print 0}' "$file"
}
get_skill_usage() {
  local name="$1" a b
  a="$(get_tsv_count "$SKILLTOOL_TSV" "$name")"
  b="$(get_tsv_count "$SLASHCMD_TSV" "$name")"
  echo $((a + b))
}
get_command_usage() { get_tsv_count "$SLASHCMD_TSV" "$1"; }
get_subagent_usage() { get_tsv_count "$SUBAGENT_TSV" "$1"; }
get_mcp_usage() {
  local server="$1" c
  [ -s "$MCP_RAW" ] || { echo 0; return; }
  c="$("$GREP" -c "^mcp__${server}__" "$MCP_RAW" 2>/dev/null)"
  echo "${c:-0}"
}
get_plugin_namespace_usage() {
  # <namespace> (plugin.json の name) を持つ "<namespace>:<skill>" 形式の
  # Skillツール呼び出し・スラッシュコマンドに加え、プラグイン内蔵MCPサーバー
  # (mcp__plugin_<namespace>_<server>__*) の呼び出しも合算する。間接指標。
  local ns="$1" a b c
  a="$(awk -F'\t' -v p="${ns}:" 'index($1,p)==1{s+=$2} END{print s+0}' "$SKILLTOOL_TSV")"
  b="$(awk -F'\t' -v p="${ns}:" 'index($1,p)==1{s+=$2} END{print s+0}' "$SLASHCMD_TSV")"
  c=0
  if [ -s "$MCP_RAW" ]; then
    c="$("$GREP" -c "^mcp__plugin_${ns}_" "$MCP_RAW" 2>/dev/null)"
    c="${c:-0}"
  fi
  echo $((a + b + c))
}

log "=== フェーズB: dotfiles スコープ ==="

# ---- A. dotfiles: skill --------------------------------------------
# 配布先の実体確認: claude/skills/, codex/skills/, gemini/config/skills/ の
# symlink が shared/skills/<category>/<name> を指しているかを実体パス比較で検証する。
skill_targets() {
  local skill_dir="$1" name="$2" real_skill csv=""
  real_skill="$(realpath "$skill_dir" 2>/dev/null)"
  for pair in "claude/skills:Claude" "codex/skills:Codex" "gemini/config/skills:Gemini"; do
    local dir="${pair%%:*}" label="${pair##*:}"
    local cand="$DOTFILES_ROOT/$dir/$name"
    if [ -e "$cand" ]; then
      local real_cand
      real_cand="$(realpath "$cand" 2>/dev/null)"
      if [ "$real_cand" = "$real_skill" ]; then
        csv="${csv:+$csv,}$label"
      fi
    fi
  done
  echo "$csv"
}

for category in common claude-only codex-only; do
  catdir="$DOTFILES_ROOT/shared/skills/$category"
  [ -d "$catdir" ] || continue
  while IFS= read -r skillmd; do
    skill_dir="$(dirname "$skillmd")"
    name="$(basename "$skill_dir")"
    relpath="${skill_dir#"$DOTFILES_ROOT"/}"
    fm_name="$(get_frontmatter_name "$skillmd")"
    [ -n "$fm_name" ] && name="$fm_name"
    targets="$(skill_targets "$skill_dir" "$(basename "$skill_dir")")"
    lm="$(git_last_modified "$DOTFILES_ROOT" "$relpath")"
    usage="$(get_skill_usage "$name")"
    emit_asset "dotfiles:skill:$name" "$name" "skill" "自作" "dotfiles" "$targets" \
      "$relpath" "$usage" "true" "$lm" ""
  done < <(find "$catdir" -mindepth 2 -maxdepth 2 -name "SKILL.md" 2>/dev/null | sort)
done

# ---- A. dotfiles: hook ------------------------------------------------
if [ -d "$DOTFILES_ROOT/claude/hooks" ]; then
  while IFS= read -r hook; do
    base="$(basename "$hook")"
    [ "$base" = ".DS_Store" ] && continue
    name="${base%.*}"
    relpath="${hook#"$DOTFILES_ROOT"/}"
    lm="$(git_last_modified "$DOTFILES_ROOT" "$relpath")"
    perm_note="実行権限あり"
    [ -x "$hook" ] || perm_note="実行権限なし（要修正）"
    emit_asset "dotfiles:hook:$name" "$name" "hook" "自作" "dotfiles" "Claude" \
      "$relpath" "null" "false" "$lm" "整合性チェック: $perm_note"
  done < <(find "$DOTFILES_ROOT/claude/hooks" -maxdepth 1 -type f 2>/dev/null | sort)
fi
# claude/settings.json の hooks 定義（claude/hooks/ 以外を指すスクリプト）
if [ -f "$DOTFILES_ROOT/claude/claude_message.sh" ]; then
  hookfile="$DOTFILES_ROOT/claude/claude_message.sh"
  relpath="${hookfile#"$DOTFILES_ROOT"/}"
  lm="$(git_last_modified "$DOTFILES_ROOT" "$relpath")"
  perm_note="実行権限あり"
  [ -x "$hookfile" ] || perm_note="実行権限なし（要修正）"
  emit_asset "dotfiles:hook:claude_message" "claude_message" "hook" "自作" "dotfiles" "Claude" \
    "$relpath" "null" "false" "$lm" "settings.json の Stop/Notification/PostToolUse/PostToolUseFailure から参照。整合性チェック: $perm_note"
fi

# ---- A. dotfiles: context (shared/agents/*.md) ------------------------
# 実際の配布経路を確認済み: core.md は Claude(@参照)/Codex/Gemini('task sync-agents'で
# ~/.codex/AGENTS.md, ~/.gemini/AGENTS.md に連結生成)全てに使われる。diff-*.md は
# 対応CLIのみ。
declare_context() {
  local file="$1" name="$2" targets="$3"
  [ -f "$file" ] || return
  local relpath="${file#"$DOTFILES_ROOT"/}"
  local lm; lm="$(git_last_modified "$DOTFILES_ROOT" "$relpath")"
  # @ 参照の整合性チェック（このファイル自身の中に @path があれば実在確認）
  local refnote="@参照なし"
  local refs
  refs="$($GREP -oE '^@[^[:space:]]+' "$file" 2>/dev/null)"
  if [ -n "$refs" ]; then
    local ok=0 ng=0
    while IFS= read -r r; do
      local p="${r#@}"
      p="${p/#\~/$HOME}"
      if [ -e "$p" ]; then ok=$((ok+1)); else ng=$((ng+1)); fi
    done <<< "$refs"
    refnote="@参照 ${ok}件OK/${ng}件NG"
  fi
  emit_asset "dotfiles:context:$name" "$name" "context" "自作" "dotfiles" "$targets" \
    "$relpath" "null" "false" "$lm" "整合性チェック: $refnote"
}
declare_context "$DOTFILES_ROOT/shared/agents/core.md" "core" "Claude,Codex,Gemini"
declare_context "$DOTFILES_ROOT/shared/agents/diff-claude.md" "diff-claude" "Claude"
declare_context "$DOTFILES_ROOT/shared/agents/diff-codex.md" "diff-codex" "Codex"
declare_context "$DOTFILES_ROOT/shared/agents/diff-gemini.md" "diff-gemini" "Gemini"

# codex/rules/* (中身のあるファイルのみ。.gitkeep はプレースホルダなので除外)
if [ -d "$DOTFILES_ROOT/codex/rules" ]; then
  while IFS= read -r rf; do
    base="$(basename "$rf")"
    [ "$base" = ".gitkeep" ] && continue
    name="codex-rules-${base%.*}"
    declare_context "$rf" "$name" "Codex"
  done < <(find "$DOTFILES_ROOT/codex/rules" -maxdepth 1 -type f 2>/dev/null | sort)
fi

# ---- A. dotfiles: MCP ---------------------------------------------------
# claude/.mcp.json: 正しくは "mcpServers" 直下がスキーマだが、実ファイルには
# "cocoindex-code" がトップレベルの兄弟キーとして紛れ込んでおり、これは
# Claude Code から実際には読み込まれない設定ミスの疑いがある。存在は資産として
# 記録しつつ notes で明示する。
CLAUDE_MCP_JSON="$DOTFILES_ROOT/claude/.mcp.json"
declare -a CLAUDE_MCP_NAMES=()
declare -a CLAUDE_MCP_BROKEN=()
if [ -f "$CLAUDE_MCP_JSON" ]; then
  while IFS= read -r n; do
    [ -n "$n" ] && CLAUDE_MCP_NAMES+=("$n")
  done < <(jq -r '.mcpServers // {} | keys[]?' "$CLAUDE_MCP_JSON" 2>/dev/null)
  while IFS= read -r n; do
    [ -n "$n" ] && CLAUDE_MCP_BROKEN+=("$n")
  done < <(jq -r 'to_entries[] | select(.key != "mcpServers") | select(.value.command or .value.url or .value.type) | .key' "$CLAUDE_MCP_JSON" 2>/dev/null)
fi

CODEX_CONFIG="$DOTFILES_ROOT/codex/config.toml"
declare -a CODEX_MCP_NAMES=()
if [ -f "$CODEX_CONFIG" ]; then
  while IFS= read -r n; do
    [ -n "$n" ] && CODEX_MCP_NAMES+=("$n")
  done < <("$GREP" -oE '^\[mcp_servers\.[A-Za-z0-9_-]+\]' "$CODEX_CONFIG" | sed -E 's/^\[mcp_servers\.([A-Za-z0-9_-]+)\]/\1/' | sort -u)
fi

# claude側・codex側それぞれの正規名リストと壊れリストを合わせて集合を作る
declare -a ALL_DOTFILES_MCP=()
for n in "${CLAUDE_MCP_NAMES[@]:-}" "${CLAUDE_MCP_BROKEN[@]:-}" "${CODEX_MCP_NAMES[@]:-}"; do
  [ -z "$n" ] && continue
  found=0
  for x in "${ALL_DOTFILES_MCP[@]:-}"; do [ "$x" = "$n" ] && found=1 && break; done
  [ "$found" -eq 0 ] && ALL_DOTFILES_MCP+=("$n")
done

in_list() { local needle="$1"; shift; for x in "$@"; do [ "$x" = "$needle" ] && return 0; done; return 1; }

for n in "${ALL_DOTFILES_MCP[@]:-}"; do
  targets=""
  in_list "$n" "${CLAUDE_MCP_NAMES[@]:-}" && targets="${targets:+$targets,}Claude"
  in_list "$n" "${CLAUDE_MCP_BROKEN[@]:-}" && targets="${targets:+$targets,}Claude"
  in_list "$n" "${CODEX_MCP_NAMES[@]:-}" && targets="${targets:+$targets,}Codex"
  path="claude/.mcp.json, codex/config.toml"
  notes=""
  if in_list "$n" "${CLAUDE_MCP_BROKEN[@]:-}"; then
    notes="設定ミスの疑い: claude/.mcp.json の mcpServers 直下ではなくトップレベルに定義されており、実際には読み込まれない可能性が高い"
  fi
  lm="$(git_last_modified "$DOTFILES_ROOT" "claude/.mcp.json")"
  lm2="$(git_last_modified "$DOTFILES_ROOT" "codex/config.toml")"
  [ -z "$lm" ] || { [ -n "$lm2" ] && [ "$lm2" \> "$lm" ] && lm="$lm2"; }
  [ -z "$lm" ] && lm="$lm2"
  usage="$(get_mcp_usage "$n")"
  emit_asset "dotfiles:mcp:$n" "$n" "MCP" "自作" "dotfiles" "$targets" "$path" \
    "$usage" "true" "$lm" "$notes"
done

log "=== フェーズC: global スコープ ==="

# ---- B. global: plugin --------------------------------------------------
INSTALLED_PLUGINS_JSON="$HOME/.claude/plugins/installed_plugins.json"
CLAUDE_SETTINGS_JSON="$HOME/.claude/settings.json"

declare -a REFERENCED_INSTALL_PATHS=()
if [ -f "$INSTALLED_PLUGINS_JSON" ]; then
  while IFS= read -r p; do
    [ -n "$p" ] && REFERENCED_INSTALL_PATHS+=("$p")
  done < <(jq -r '.plugins // {} | to_entries[] | .value[]?.installPath' "$INSTALLED_PLUGINS_JSON" 2>/dev/null)

  while IFS= read -r pluginkey; do
    [ -z "$pluginkey" ] && continue
    pname="${pluginkey%%@*}"
    # jq の // 演算子は false を falsy 扱いして右辺にフォールバックしてしまうため、
    # has() で存在確認してから tostring で取り出す（true/false を取り違えないため）。
    enabled="$(jq -r --arg k "$pluginkey" 'if (.enabledPlugins | has($k)) then (.enabledPlugins[$k] | tostring) else "unset" end' "$CLAUDE_SETTINGS_JSON" 2>/dev/null)"
    case "$enabled" in
      true) status="有効" ;;
      false) status="無効" ;;
      *) status="不明(設定未記載)" ;;
    esac
    # installPath は複数（scope違い）ありうる。scope=user のものを代表とし、
    # 無ければ先頭のものにフォールバックする。
    installpath="$(jq -r --arg k "$pluginkey" '(.plugins[$k] | (map(select(.scope=="user")) + .))[0].installPath // empty' "$INSTALLED_PLUGINS_JSON" 2>/dev/null)"
    version="$(jq -r --arg k "$pluginkey" '(.plugins[$k] | (map(select(.scope=="user")) + .))[0].version // "unknown"' "$INSTALLED_PLUGINS_JSON" 2>/dev/null)"
    ns="$pname"
    if [ -n "$installpath" ] && [ -f "$installpath/.claude-plugin/plugin.json" ]; then
      pn="$(jq -r '.name // empty' "$installpath/.claude-plugin/plugin.json" 2>/dev/null)"
      [ -n "$pn" ] && ns="$pn"
    fi
    skill_count=0
    agent_count=0
    if [ -n "$installpath" ] && [ -d "$installpath/skills" ]; then
      skill_count="$(find "$installpath/skills" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')"
    fi
    if [ -n "$installpath" ] && [ -d "$installpath/agents" ]; then
      agent_count="$(find "$installpath/agents" -maxdepth 1 -name "*.md" 2>/dev/null | wc -l | tr -d ' ')"
    fi
    lm=""
    [ -n "$installpath" ] && [ -e "$installpath" ] && lm="$(stat -f "%Sm" -t "%Y-%m-%d" "$installpath" 2>/dev/null)"
    usage="$(get_plugin_namespace_usage "$ns")"
    notes="${status} / v${version} / skill${skill_count}件・agent${agent_count}件 / 利用実績は内包skill・agentの呼び出し合算（間接指標）"
    emit_asset "global:plugin:$pname" "$pname" "plugin" "プラグイン" "global" "Claude" \
      "$installpath" "$usage" "true" "$lm" "$notes"
  done < <(jq -r '.plugins // {} | keys[]?' "$INSTALLED_PLUGINS_JSON" 2>/dev/null)
fi

# ---- B. global: MCP (~/.claude.json) ------------------------------------
GLOBAL_CLAUDE_JSON="$HOME/.claude.json"
if [ -f "$GLOBAL_CLAUDE_JSON" ]; then
  while IFS= read -r n; do
    [ -z "$n" ] && continue
    usage="$(get_mcp_usage "$n")"
    lm="$(stat -f "%Sm" -t "%Y-%m-%d" "$GLOBAL_CLAUDE_JSON" 2>/dev/null)"
    notes=""
    if in_list "$n" "${ALL_DOTFILES_MCP[@]:-}"; then
      notes="同名のMCPが dotfiles:mcp:$n としても定義されており重複の疑い"
    fi
    emit_asset "global:mcp:$n" "$n" "MCP" "自作" "global" "Claude" "~/.claude.json" \
      "$usage" "true" "$lm" "$notes"
  done < <(jq -r '.mcpServers // {} | keys[]?' "$GLOBAL_CLAUDE_JSON" 2>/dev/null)
fi

# ---- B. global: memory (~/.claude/projects/*/memory/) -------------------
if [ -d "$PROJECTS_DIR" ]; then
  while IFS= read -r memdir; do
    projdir="$(dirname "$memdir")"
    slug="$(basename "$projdir")"
    friendly="$slug"
    friendly="${friendly#-Users-yoshihiko-ghq-github-com-yoshihiko555-}"
    friendly="${friendly#-Users-yoshihiko-ghq-github-anvil-}"
    friendly="${friendly#-Users-yoshihiko-}"
    newest_file="$(find "$memdir" -type f -name "*.md" -exec stat -f "%m %N" {} \; 2>/dev/null | sort -rn | head -1 | awk '{print $2}')"
    lm=""
    [ -n "$newest_file" ] && lm="$(stat -f "%Sm" -t "%Y-%m-%d" "$newest_file" 2>/dev/null)"
    file_count="$(find "$memdir" -type f -name "*.md" 2>/dev/null | wc -l | tr -d ' ')"
    emit_asset "project:memory:$friendly" "$friendly" "memory" "自作" "project" "Claude" \
      "${memdir#"$HOME"/}" "null" "false" "$lm" "MEMORY.md + フィードバック/プロジェクトファイル計${file_count}件"
  done < <(find "$PROJECTS_DIR" -mindepth 2 -maxdepth 2 -type d -name memory 2>/dev/null | sort)
fi

log "=== フェーズD: project スコープ (ghq) ==="

# ---- C. project スコープ --------------------------------------------------
GHQ_ROOT="$HOME/ghq"
EXCLUDE_REPOS_RE='/ai-valification/reference/(claude-code-harness|claude-code-orchestra|everything-claude-code|multi-agent-shogun)$'

ALL_GIT_DIRS="$WORKDIR/all_git_dirs.txt"
find "$GHQ_ROOT" -mindepth 1 -maxdepth 6 -type d -name ".git" 2>/dev/null | sed 's|/\.git$||' | sort > "$ALL_GIT_DIRS"

REPO_LIST="$WORKDIR/repo_list.txt"
: > "$REPO_LIST"
while IFS= read -r repo; do
  [ -z "$repo" ] && continue
  case "$repo" in
    */.worktrees/*)
      size="$(size_mb_of "$repo")"
      emit_waste "${repo#"$HOME"/}" "$size" "takt等のworktree（棚卸し対象外。マージ済みなら削除候補）"
      continue
      ;;
  esac
  if printf '%s' "$repo" | $GREP -qE "$EXCLUDE_REPOS_RE"; then
    size="$(size_mb_of "$repo")"
    emit_waste "${repo#"$HOME"/}" "$size" "ai-valification/reference 配下の参照リポジトリ（削除候補としてレポートに記録、台帳対象外）"
    continue
  fi
  echo "$repo" >> "$REPO_LIST"
done < "$ALL_GIT_DIRS"

REPO_COUNT="$(wc -l < "$REPO_LIST" | tr -d ' ')"
log "project スコープの走査対象リポジトリ数: $REPO_COUNT"

PROJ_AGENTS_TSV="$WORKDIR/proj_agents.tsv"
PROJ_SKILLS_TSV="$WORKDIR/proj_skills.tsv"
PROJ_COMMANDS_TSV="$WORKDIR/proj_commands.tsv"
: > "$PROJ_AGENTS_TSV"; : > "$PROJ_SKILLS_TSV"; : > "$PROJ_COMMANDS_TSV"

now_epoch="$(date +%s)"

while IFS= read -r repo; do
  [ -z "$repo" ] && continue
  reponame="$(basename "$repo")"

  # node_modules / .venv / vendor / .worktrees を除外して .claude ディレクトリを探す
  while IFS= read -r claudedir; do
    if [ -d "$claudedir/agents" ]; then
      while IFS= read -r af; do
        base="$(basename "$af")"
        [ "$base" = ".DS_Store" ] && continue
        n="$(get_frontmatter_name "$af")"
        [ -z "$n" ] && n="${base%.md}"
        printf '%s\t%s\n' "$n" "$repo" >> "$PROJ_AGENTS_TSV"
      done < <(find "$claudedir/agents" -maxdepth 1 -name "*.md" 2>/dev/null)
    fi
    if [ -d "$claudedir/skills" ]; then
      while IFS= read -r sf; do
        n="$(get_frontmatter_name "$sf")"
        [ -z "$n" ] && n="$(basename "$(dirname "$sf")")"
        printf '%s\t%s\n' "$n" "$repo" >> "$PROJ_SKILLS_TSV"
      done < <(find "$claudedir/skills" -mindepth 2 -maxdepth 2 -name "SKILL.md" 2>/dev/null)
    fi
    if [ -d "$claudedir/commands" ]; then
      while IFS= read -r cf; do
        base="$(basename "$cf")"
        [ "$base" = ".DS_Store" ] && continue
        n="${base%.*}"
        printf '%s\t%s\n' "$n" "$repo" >> "$PROJ_COMMANDS_TSV"
      done < <(find "$claudedir/commands" -maxdepth 1 -type f 2>/dev/null)
    fi
  done < <(find "$repo" \
    \( -name node_modules -o -name .venv -o -name vendor -o -name .git -o -name .worktrees \
       -o -path "*/reference/claude-code-harness" -o -path "*/reference/claude-code-orchestra" \
       -o -path "*/reference/everything-claude-code" -o -path "*/reference/multi-agent-shogun" \) -prune \
    -o -type d -name ".claude" -print 2>/dev/null)

  # repo単位の context (root の CLAUDE.md / AGENTS.md のみ)
  ctx_file=""
  if [ -f "$repo/CLAUDE.md" ]; then ctx_file="$repo/CLAUDE.md"; fi
  if [ -f "$repo/AGENTS.md" ]; then
    if [ -z "$ctx_file" ]; then ctx_file="$repo/AGENTS.md"; else ctx_file="$ctx_file,$repo/AGENTS.md"; fi
  fi
  if [ -n "$ctx_file" ]; then
    lm="$(git -C "$repo" log -1 --format=%cs 2>/dev/null)"
    # @ 参照の整合性チェック（CLAUDE.md/AGENTS.md それぞれ）
    ok=0; ng=0
    for f in $(echo "$ctx_file" | tr ',' ' '); do
      refs="$($GREP -oE '^@[^[:space:]]+' "$f" 2>/dev/null)"
      [ -z "$refs" ] && continue
      while IFS= read -r r; do
        p="${r#@}"
        case "$p" in
          /*) : ;;
          *) p="$repo/$p" ;;
        esac
        p="${p/#\~/$HOME}"
        if [ -e "$p" ]; then ok=$((ok+1)); else ng=$((ng+1)); fi
      done <<< "$refs"
    done
    refnote="整合性チェック: @参照 ${ok}件OK/${ng}件NG"
    relctx="${ctx_file//$repo\//}"
    emit_asset "project:context:$reponame" "$reponame" "context" "自作" "project" "Claude" \
      "$relctx" "null" "false" "$lm" "$refnote"
  fi

  # 6か月以上コミットが無いリポジトリはAI資産をwaste候補として記録
  last_commit_epoch="$(git -C "$repo" log -1 --format=%ct 2>/dev/null)"
  if [ -n "$last_commit_epoch" ]; then
    age_days=$(( (now_epoch - last_commit_epoch) / 86400 ))
    if [ "$age_days" -ge 183 ] && [ -d "$repo/.claude" ]; then
      size="$(size_mb_of "$repo/.claude")"
      emit_waste "${repo#"$HOME"/}/.claude" "$size" "${age_days}日間コミットなし。AI資産の陳腐化リスクあり"
    fi
  fi
done < "$REPO_LIST"

# ユニーク名で project:agent / project:skill / project:command を集約
emit_unique_project_assets() {
  local tsv="$1" type="$2"
  [ -s "$tsv" ] || return
  local names
  names="$(cut -f1 "$tsv" | sort -u)"
  while IFS= read -r n; do
    [ -z "$n" ] && continue
    local repos count path lm usage
    repos="$(awk -F'\t' -v n="$n" '$1==n{print $2}' "$tsv" | sort -u)"
    count="$(printf '%s\n' "$repos" | sed '/^$/d' | wc -l | tr -d ' ')"
    path="$(printf '%s\n' "$repos" | sed '/^$/d' | tr '\n' ';' | sed 's/;$//')"
    lm=""
    while IFS= read -r r; do
      [ -z "$r" ] && continue
      local this_lm
      case "$type" in
        agent) this_lm="$(git_last_modified "$r" ".claude/agents")" ;;
        skill) this_lm="$(git_last_modified "$r" ".claude/skills")" ;;
        command) this_lm="$(git_last_modified "$r" ".claude/commands")" ;;
      esac
      if [ -n "$this_lm" ] && { [ -z "$lm" ] || [ "$this_lm" \> "$lm" ]; }; then lm="$this_lm"; fi
    done <<< "$repos"
    local note=""
    [ "$count" -gt 1 ] && note="${count}リポジトリに重複"
    # id のプレフィックスは設計書の例 (project:agent:code-reviewer) に合わせて
    # "agent" のままにするが、出力契約のtype列挙は skill|subagent|command|... で
    # "agent" が無いため、type フィールドだけ "subagent" に変換して出す。
    local out_type="$type"
    [ "$type" = "agent" ] && out_type="subagent"
    case "$type" in
      agent) usage="$(get_subagent_usage "$n")" ;;
      skill) usage="$(get_skill_usage "$n")" ;;
      command) usage="$(get_command_usage "$n")" ;;
    esac
    emit_asset "project:${type}:$n" "$n" "$out_type" "自作" "project" "Claude" "$path" \
      "$usage" "true" "$lm" "$note"
  done <<< "$names"
}
emit_unique_project_assets "$PROJ_AGENTS_TSV" "agent"
emit_unique_project_assets "$PROJ_SKILLS_TSV" "skill"
emit_unique_project_assets "$PROJ_COMMANDS_TSV" "command"

log "=== フェーズE: waste（残骸）検出 ==="

# ---- E. waste: plugin cache の未参照バージョン ----------------------------
PLUGINS_CACHE="$HOME/.claude/plugins/cache"
if [ -d "$PLUGINS_CACHE" ]; then
  while IFS= read -r verdir; do
    ref=0
    for p in "${REFERENCED_INSTALL_PATHS[@]:-}"; do
      # installed_plugins.json のパスは大文字小文字がずれることがある
      # （例: 実ディレクトリ "Notion" だが installPath は "notion"）。
      # macOSのファイルシステムは大小文字非依存なので -ef (inode比較) で判定する。
      [ -n "$p" ] && [ "$p" -ef "$verdir" ] && ref=1 && break
    done
    if [ "$ref" -eq 0 ]; then
      pluginname="$(basename "$(dirname "$verdir")")"
      version="$(basename "$verdir")"
      size="$(size_mb_of "$verdir")"
      emit_waste "${verdir#"$HOME"/}" "$size" "$pluginname の旧バージョン ($version)。installed_plugins.json から参照されていない"
    fi
  done < <(find "$PLUGINS_CACHE" -mindepth 3 -maxdepth 3 -type d 2>/dev/null | sort)
fi

# ---- E. waste: marketplace .bak / 未参照marketplace ------------------------
MARKETPLACES="$HOME/.claude/plugins/marketplaces"
if [ -d "$MARKETPLACES" ]; then
  while IFS= read -r mdir; do
    mname="$(basename "$mdir")"
    size="$(size_mb_of "$mdir")"
    case "$mname" in
      *.bak)
        emit_waste "${mdir#"$HOME"/}" "$size" "marketplace の .bak バックアップディレクトリ"
        ;;
      *)
        referenced=0
        if [ -f "$INSTALLED_PLUGINS_JSON" ]; then
          while IFS= read -r k; do
            [ "${k##*@}" = "$mname" ] && referenced=1 && break
          done < <(jq -r '.plugins // {} | keys[]?' "$INSTALLED_PLUGINS_JSON" 2>/dev/null)
        fi
        if [ "$referenced" -eq 0 ]; then
          emit_waste "${mdir#"$HOME"/}" "$size" "インストール済みプラグインから参照されていない orphan marketplace"
        fi
        ;;
    esac
  done < <(find "$MARKETPLACES" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
fi

# ---- E. waste: 空ディレクトリ（.DS_Store のみ含む場合を含む）----------------
is_effectively_empty() {
  local d="$1"
  [ -d "$d" ] || return 1
  local n
  n="$(find "$d" -mindepth 1 ! -name ".DS_Store" 2>/dev/null | wc -l | tr -d ' ')"
  [ "$n" -eq 0 ]
}
for d in "claude/agents" "claude/rules" "claude/templates"; do
  full="$DOTFILES_ROOT/$d"
  if is_effectively_empty "$full"; then
    emit_waste "$d" "0" "空ディレクトリ（.DS_Store 以外のファイルなし）"
  fi
done
if is_effectively_empty "$HOME/.claude/commands"; then
  emit_waste "~/.claude/commands" "0" "空ディレクトリ"
fi

# ---- E. waste: 0バイトの設定ファイル ---------------------------------------
for f in "$HOME/.gemini/config/mcp_config.json"; do
  if [ -f "$f" ] && [ ! -s "$f" ]; then
    emit_waste "${f/#$HOME/~}" "0" "0バイトの設定ファイル（未設定のまま放置）"
  fi
done

log "=== フェーズF: JSON組み立て ==="

ASSETS_JSON="$(jq -s '.' "$ASSETS_ND" 2>/dev/null)"
if [ -z "$ASSETS_JSON" ]; then ASSETS_JSON='[]'; fi
WASTE_JSON="$(jq -s '.' "$WASTE_ND" 2>/dev/null)"
if [ -z "$WASTE_JSON" ]; then WASTE_JSON='[]'; fi

jq -n \
  --arg collected_at "$TODAY" \
  --argjson assets "$ASSETS_JSON" \
  --argjson waste "$WASTE_JSON" \
  '{
    collected_at: $collected_at,
    assets: $assets,
    stats: {
      total: ($assets | length),
      by_type: ($assets | group_by(.type) | map({key: .[0].type, value: length}) | from_entries),
      by_scope: ($assets | group_by(.scope) | map({key: .[0].scope, value: length}) | from_entries)
    },
    waste: $waste
  }'

log "完了。assets=$(echo "$ASSETS_JSON" | jq 'length') waste=$(echo "$WASTE_JSON" | jq 'length')"
