#!/usr/bin/env bash
# 実際の Dropbox には触れず、一時ディレクトリで alfred-workflow-links.sh の張り方・後始末・失敗時の停止を確認する。
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/scripts/alfred-workflow-links.sh"
work=$(mktemp -d "${TMPDIR:-/tmp}/test-alfred-links.XXXXXX")
trap 'chmod -R u+w "$work"; rm -rf "$work"' EXIT

U1=11111111-1111-1111-1111-111111111111
U2=22222222-2222-2222-2222-222222222222
U3=33333333-3333-3333-3333-333333333333
U4=44444444-4444-4444-4444-444444444444
wf="$work/workflows"
src="$work/alfred"
mkdir -p "$wf" "$src/a" "$src/b" "$work/elsewhere"
export ALFRED_WORKFLOWS_DIR="$wf" ALFRED_SRC_DIR="$src" ALFRED_LINKS_STATE="$work/state/links"

run() { bash "$SCRIPT" apply "$@"; }
fails() { if run "$@" >"$work/output" 2>&1; then
  echo "失敗するはずが成功した: $*" >&2
  exit 1
fi; }
points_to() { [[ "$(readlink "$wf/user.workflow.$1")" == "$2" ]]; }

# 初回: リンクが無い状態から張る
run "$U1=a" "$U2=b" >/dev/null
points_to "$U1" "$src/a"
points_to "$U2" "$src/b"
[[ "$(cat "$ALFRED_LINKS_STATE")" == "$U1"$'\n'"$U2" ]]
echo '成功: 初回に張る'

# 変更が無ければ workflows/ に書き込まない（書けない状態でも成功する）
chmod 555 "$wf"
run "$U1=a" "$U2=b" >"$work/output"
[[ ! -s "$work/output" ]]
echo '成功: 一致していれば書き込まない'

# 張り直しが要るのに書けないときは非 0 で止まり、記録も更新しない
cp "$ALFRED_LINKS_STATE" "$work/state-before"
fails "$U1=a" "$U2=b" "$U3=a"
grep -q 'を変更できない' "$work/output"
cmp "$ALFRED_LINKS_STATE" "$work/state-before"
chmod 755 "$wf"
echo '成功: 書けないときは止まる'

# 旧 home-manager の store パスを指すリンクを張り替える
ln -sfn /nix/store/xxxx-home-manager-files/workflows/user.workflow.$U1 "$wf/user.workflow.$U1"
run "$U1=a" "$U2=b" >/dev/null
points_to "$U1" "$src/a"
echo '成功: 古いリンクを張り替える'

# 実体のディレクトリには触らない
mkdir "$wf/user.workflow.$U3"
fails "$U1=a" "$U3=a"
grep -q 'リンクではない実体' "$work/output"
[[ -d "$wf/user.workflow.$U3" && ! -L "$wf/user.workflow.$U3" ]]
rmdir "$wf/user.workflow.$U3"
echo '成功: 実体ディレクトリは拒否する'

# 表から消した分は消す。alfred/ 以外を指すリンクは残す
printf '%s\n' "$U1" "$U2" "$U4" >"$ALFRED_LINKS_STATE"
ln -s "$work/elsewhere" "$wf/user.workflow.$U4"
run "$U1=a" >"$work/output" 2>&1
[[ ! -e "$wf/user.workflow.$U2" && ! -L "$wf/user.workflow.$U2" ]]
points_to "$U4" "$work/elsewhere"
grep -q '指していないので残す' "$work/output"
[[ "$(cat "$ALFRED_LINKS_STATE")" == "$U1" ]]
echo '成功: 表から消した分だけ消す'

# 入力の不備で止まる
fails "$U1=missing"
fails "not-a-uuid=a"
ALFRED_WORKFLOWS_DIR="$work/absent" fails "$U1=a"
[[ ! -e "$work/absent" ]]
echo '成功: 入力の不備・workflows が無いときは止まる（作らない）'
