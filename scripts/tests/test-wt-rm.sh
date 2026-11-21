#!/usr/bin/env bash
# 一時リポジトリで wt rm を呼び、push していないコミットがあるブランチだけ残すことを確認する。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ZSH_BIN="$(command -v zsh)"
work=$(mktemp -d "${TMPDIR:-/tmp}/test-wt-rm.XXXXXX")
trap 'rm -rf "$work"' EXIT

# 利用者の git 設定（hook・includeIf）を読まない
cat >"$work/gitconfig" <<'EOF'
[user]
	name = test
	email = test@example.com
[gtr "worktrees"]
	dir = .worktrees
EOF
export GIT_CONFIG_GLOBAL="$work/gitconfig" GIT_CONFIG_NOSYSTEM=1

git init -q --bare -b main "$work/remote.git"
git clone -q "$work/remote.git" "$work/repo" 2>/dev/null
cd "$work/repo"
git commit -q --allow-empty -m init
git push -q origin HEAD:main
git remote set-head origin main >/dev/null

wt_path() { git gtr go "$1" 2>/dev/null; }
new_wt() {
  git gtr new "$1" --yes --no-fetch --no-hooks >/dev/null 2>&1
  if [[ "${2:-}" == commit ]]; then
    git -C "$(wt_path "$1")" commit -q --allow-empty -m "work on $1"
  fi
}
run_wt() {
  DOTFILES="$ROOT" "$ZSH_BIN" -f -c 'source "$DOTFILES/shell/zsh/wt.zsh"; wt "$@"' wt "$@" >"$work/out" 2>&1
}
has_branch() { git show-ref --verify --quiet "refs/heads/$1"; }
has_wt() { git worktree list --porcelain | grep -qx "branch refs/heads/$1"; }
refute() {
  if "$@"; then
    echo "失敗: $* が成り立っている" >&2
    exit 1
  fi
}

new_wt task/local commit
run_wt rm task/local --yes
refute has_wt task/local
has_branch task/local
grep -q 'task/local には push していないコミットがある' "$work/out"
echo '成功: push していないコミットがあるブランチは、worktree だけ消してブランチを残す'

new_wt task/pushed commit
git -C "$(wt_path task/pushed)" push -q -u origin task/pushed 2>/dev/null
run_wt rm task/pushed --yes
refute has_wt task/pushed
refute has_branch task/pushed
echo '成功: push 済みのブランチは消す'

new_wt task/gone commit
git -C "$(wt_path task/gone)" push -q -u origin task/gone 2>/dev/null
git push -q origin --delete task/gone 2>/dev/null
git fetch -q --prune
run_wt rm task/gone --yes
refute has_branch task/gone
echo '成功: upstream が remote 側で消えたブランチ（squash merge 後など）は消す'

new_wt task/empty
run_wt rm task/empty --yes
refute has_branch task/empty
echo '成功: main から何も足していないブランチは消す'

new_wt task/forced commit
run_wt rm task/forced --yes --delete-branch
refute has_branch task/forced
echo '成功: --delete-branch を明示すると push していなくても消す'

new_wt task/mix-local commit
new_wt task/mix-empty
run_wt rm task/mix-local task/mix-empty --yes
refute has_wt task/mix-local
refute has_wt task/mix-empty
has_branch task/mix-local
refute has_branch task/mix-empty
echo '成功: 複数指定でも、残すブランチと消すブランチを分ける'
