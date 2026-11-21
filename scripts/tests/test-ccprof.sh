#!/usr/bin/env bash
# 偽の claude を PATH に置き、ccprof が profile ごとに渡す引数と、誤った名前の扱いを確認する。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ZSH_BIN="$(command -v zsh)"
work=$(mktemp -d "${TMPDIR:-/tmp}/test-ccprof.XXXXXX")
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/bin"
cat >"$work/bin/claude" <<'EOF'
#!/usr/bin/env bash
echo "CLAUDE_PROFILE=${CLAUDE_PROFILE-unset} $*" >>"$CCPROF_LOG"
EOF
chmod +x "$work/bin/claude"

run_ccprof() {
  : >"$work/log"
  env -u CLAUDE_PROFILE PATH="$work/bin:$PATH" CCPROF_LOG="$work/log" DOTFILES="$ROOT" \
    CLAUDE_PROFILES_DIR="${PROFILES_DIR:-$ROOT/claude/profiles}" \
    "$ZSH_BIN" -f -c 'source "$DOTFILES/shell/zsh/claude.zsh"; ccprof "$@"' ccprof "$@" >"$work/out" 2>&1
}

dir="$ROOT/claude/profiles"
run_ccprof daily -p hello
diff -u - "$work/log" <<EOF
CLAUDE_PROFILE=daily --settings $dir/daily/settings.json --append-system-prompt-file $dir/daily/prompt.md -p hello
EOF
echo '成功: settings.json と prompt.md を重ね、profile 名を渡し、残りの引数をそのまま渡す'

mkdir -p "$work/profiles/only-prompt"
touch "$work/profiles/only-prompt/prompt.md"
PROFILES_DIR="$work/profiles" run_ccprof only-prompt
diff -u - "$work/log" <<EOF
CLAUDE_PROFILE=only-prompt --append-system-prompt-file $work/profiles/only-prompt/prompt.md
EOF
echo '成功: profile にあるファイルだけを重ねる'

for args in nope "" --help; do
  if run_ccprof $args; then exit 1; fi
  [[ ! -s "$work/log" ]]
  grep -q 'profiles: daily' "$work/out"
done
echo '成功: 無い profile・引数なし・オプションだけでは claude を呼ばず、profile の一覧を出す'

for f in "$dir"/*/settings.json; do jq -e . "$f" >/dev/null; done
while IFS= read -r pattern; do
  name="${pattern#\*\*/}"
  [[ -f "$ROOT/$name" ]]
  grep -q "/dotfiles/$name\$" "$ROOT/claude/CLAUDE.md"
done < <(jq -r '.claudeMdExcludes[]?' "$dir"/*/settings.json)
echo '成功: settings.json は JSON として読め、claudeMdExcludes が外すファイルは実在して CLAUDE.md から import されている'
