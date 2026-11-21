#!/usr/bin/env bash
# 偽の claude と fzf を PATH に置き、ccp（Claude の profile 起動）が渡す引数と、選択・誤った名前の扱いを確認する。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ZSH_BIN="$(command -v zsh)"
work=$(mktemp -d "${TMPDIR:-/tmp}/test-ccprof.XXXXXX")
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/bin" "$work/fzfbin"
cat >"$work/bin/claude" <<'EOF'
#!/usr/bin/env bash
echo "CLAUDE_PROFILE=${CLAUDE_PROFILE-unset} $*" >>"$CCP_LOG"
EOF
# 渡された候補を記録し、FZF_PICK を選んだことにする。空なら取り消し扱い。
cat >"$work/fzfbin/fzf" <<'EOF'
#!/usr/bin/env bash
cat >"$CCP_FZF_INPUT"
[[ -n "${FZF_PICK:-}" ]] || exit 130
echo "$FZF_PICK"
EOF
chmod +x "$work/bin/claude" "$work/fzfbin/fzf"

run_ccp() {
  : >"$work/log"
  : >"$work/fzf-input"
  env -u CLAUDE_PROFILE PATH="${CCP_PATH:-$work/bin:$work/fzfbin:/usr/bin:/bin}" \
    CCP_LOG="$work/log" CCP_FZF_INPUT="$work/fzf-input" DOTFILES="$ROOT" \
    CLAUDE_PROFILES_DIR="${PROFILES_DIR:-$ROOT/claude/profiles}" \
    "$ZSH_BIN" -f -c 'source "$DOTFILES/shell/zsh/claude.zsh"; ccp "$@"' ccp "$@" >"$work/out" 2>&1
}

dir="$ROOT/claude/profiles"
daily="CLAUDE_PROFILE=daily --settings $dir/daily/settings.json --append-system-prompt-file $dir/daily/prompt.md"

run_ccp daily -p hello
diff -u - "$work/log" <<<"$daily -p hello"
echo '成功: 名前を指定すると settings.json と prompt.md を重ね、profile 名を渡し、残りの引数をそのまま渡す'

mkdir -p "$work/profiles/only-prompt"
touch "$work/profiles/only-prompt/prompt.md"
PROFILES_DIR="$work/profiles" run_ccp only-prompt
diff -u - "$work/log" <<<"CLAUDE_PROFILE=only-prompt --append-system-prompt-file $work/profiles/only-prompt/prompt.md"
echo '成功: profile にあるファイルだけを重ねる'

FZF_PICK=daily run_ccp
diff -u - "$work/log" <<<"$daily"
diff -u - "$work/fzf-input" <<<"daily"
FZF_PICK=daily run_ccp -c
diff -u - "$work/log" <<<"$daily -c"
echo '成功: 名前が無いか 1 つ目がオプションなら fzf で profile を選び、引数はそのまま渡す'

if FZF_PICK='' run_ccp; then exit 1; fi
[[ ! -s "$work/log" ]]
echo '成功: fzf を取り消すと起動しない'

if run_ccp nope; then exit 1; fi
[[ ! -s "$work/log" ]]
grep -q "profile 'nope' が無い (profiles: daily)" "$work/out"
if CCP_PATH="$work/bin:/usr/bin:/bin" run_ccp; then exit 1; fi
[[ ! -s "$work/log" ]]
grep -q 'fzf が見つからない' "$work/out"
echo '成功: 無い profile や fzf が無いときは起動せず、profile の一覧を出す'

"$ZSH_BIN" -f -c 'alias ccp=claude; DOTFILES="$1"; source "$1/shell/zsh/claude.zsh"
  whence -w ccp; (( ${+functions[claude]} )) && echo "claude: function"' _ "$ROOT" >"$work/out" 2>&1 || true
diff -u - "$work/out" <<<"ccp: function"
echo '成功: 古い alias ccp が残ったシェルで読み直しても ccp を関数として定義し、claude を上書きしない'

for f in "$dir"/*/settings.json; do jq -e . "$f" >/dev/null; done
while IFS= read -r pattern; do
  name="${pattern#\*\*/}"
  [[ -f "$ROOT/$name" ]]
  grep -q "/dotfiles/$name\$" "$ROOT/claude/CLAUDE.md"
done < <(jq -r '.claudeMdExcludes[]?' "$dir"/*/settings.json)
echo '成功: settings.json は JSON として読め、claudeMdExcludes が外すファイルは実在して CLAUDE.md から import されている'
