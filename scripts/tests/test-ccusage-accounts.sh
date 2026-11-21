#!/usr/bin/env bash
# 偽の ccusage を PATH に置き、ccu が渡すディレクトリ・環境変数・引数と失敗時の扱いを確認する。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ZSH_BIN="$(command -v zsh)"
work=$(mktemp -d "${TMPDIR:-/tmp}/test-ccusage-accounts.XXXXXX")
trap 'rm -rf "$work"' EXIT

home="$work/home"
mkdir -p "$home/.claude" "$home/.claude-work" "$home/.codex" "$home/.codex-work" "$work/bin"
cat >"$work/bin/ccusage" <<'EOF'
#!/usr/bin/env bash
line="$1 ${*:2} | CLAUDE_CONFIG_DIR=${CLAUDE_CONFIG_DIR-unset} CODEX_HOME=${CODEX_HOME-unset}"
echo "$line" >>"$CCU_LOG"
[[ -n "${CCU_FAIL:-}" && "$line" == *"$CCU_FAIL"* ]] && exit 1
exit 0
EOF
chmod +x "$work/bin/ccusage"

# 親シェルに Claude Code のセッション由来の値が入っている状態で呼ぶ。
run_ccu() {
  : >"$work/log"
  env -u CLAUDE_WORK_CONFIG_DIR -u CODEX_WORK_HOME \
    HOME="$home" PATH="${CCU_PATH:-$work/bin:$PATH}" CCU_LOG="$work/log" DOTFILES="$ROOT" \
    CLAUDE_CONFIG_DIR="$home/.claude-work" CODEX_HOME="$home/.codex-work" \
    "$ZSH_BIN" -f -c 'source "$DOTFILES/shell/zsh/claude.zsh"; source "$DOTFILES/shell/zsh/codex.zsh"
      source "$DOTFILES/shell/zsh/ccusage.zsh"; ccu "$@"' ccu "$@" >"$work/out" 2>&1
}

run_ccu
diff -u - "$work/log" <<EOF
claude monthly --last 1 --compact | CLAUDE_CONFIG_DIR=unset CODEX_HOME=$home/.codex-work
claude monthly --last 1 --compact | CLAUDE_CONFIG_DIR=$home/.claude-work CODEX_HOME=$home/.codex-work
codex monthly --last 1 --compact | CLAUDE_CONFIG_DIR=$home/.claude-work CODEX_HOME=unset
codex monthly --last 1 --compact | CLAUDE_CONFIG_DIR=$home/.claude-work CODEX_HOME=$home/.codex-work
EOF
diff -u - <(grep '^== ' "$work/out") <<'EOF'
== Claude Code・個人 (~/.claude) ==
== Claude Code・仕事 (~/.claude-work) ==
== Codex・個人 (~/.codex) ==
== Codex・仕事 (~/.codex-work) ==
EOF
echo '成功: 既定の引数・4 表の順番と見出し・個人側は変数を外し仕事側は既定のディレクトリを渡す'

run_ccu daily --last 7 -o desc
[[ $(grep -c '^claude daily --last 7 -o desc |' "$work/log") == 2 ]]
[[ $(grep -c '^codex daily --last 7 -o desc |' "$work/log") == 2 ]]
run_ccu --breakdown
[[ $(grep -c ' monthly --breakdown |' "$work/log") == 4 ]]
echo '成功: 引数をそのまま渡す・先頭がオプションなら monthly を補う'

run_ccu weekly
[[ $(grep -c '^claude weekly |' "$work/log") == 2 ]]
if grep -q '^codex' "$work/log"; then exit 1; fi
[[ $(grep -c 'Codex には weekly が無いので飛ばす' "$work/out") == 2 ]]
echo '成功: Codex に無いサブコマンドでは Codex の表だけ飛ばす'

if CCU_FAIL="CLAUDE_CONFIG_DIR=unset" run_ccu; then exit 1; fi
[[ $(wc -l <"$work/log") -eq 4 ]]
echo '成功: 1 つが失敗しても残りを出し、非 0 で終わる'

rm -rf "$home/.claude-work" "$home/.codex-work"
run_ccu
[[ $(wc -l <"$work/log") -eq 2 ]]
[[ $(grep -cE '^~/\.(claude|codex)-work が無いので飛ばす$' "$work/out") == 2 ]]
echo '成功: ディレクトリが無いアカウントは飛ばし、失敗にしない'

if CCU_PATH=/usr/bin:/bin run_ccu; then exit 1; fi
grep -q 'ccusage が見つからない' "$work/out"
echo '成功: ccusage が無ければ止める'

for arg in help -h --help; do
  CCU_PATH=/usr/bin:/bin run_ccu "$arg"
  [[ ! -s "$work/log" ]]
  grep -q '── サブコマンド' "$work/out"
done
echo '成功: help / -h / --help はチートシートを出し、ccusage を呼ばない（未導入でも出る）'
