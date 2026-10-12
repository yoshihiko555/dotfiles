#!/usr/bin/env bash
# omp（oh-my-pi）を指定バージョン（省略時は GitHub Releases の latest）へ上げる。
#   使い方: ./update.sh [version]   … 通常は `nxu omp` から呼ぶ
# default.nix の version・hash を書き換えて、パッケージ単体のビルドで確認するまでを行う。
# 適用（nxs）はしない。
set -euo pipefail

repo="can1357/oh-my-pi"
asset="omp-darwin-arm64"
here=$(cd -- "$(dirname -- "$0")" && pwd)
flake=$(cd -- "$here/../.." && pwd)
nixfile="$here/default.nix"

version=${1:-$(gh api "repos/${repo}/releases/latest" --jq '.tag_name')}
version=${version#v}
current=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$nixfile")
if [ -z "$current" ]; then
  echo "default.nix から現在の version を読めません" >&2
  exit 1
fi
if [ "$version" = "$current" ]; then
  echo "omp は ${current} のままです（更新不要）"
  exit 0
fi
echo "omp: ${current} → ${version}"

# GitHub が記録しているアセットの sha256 を使えば、ここでダウンロードせずに済む
digest=$(gh api "repos/${repo}/releases/tags/v${version}" \
  --jq ".assets[] | select(.name == \"${asset}\") | .digest")
case "$digest" in
  sha256:*) ;;
  *)
    echo "v${version} の ${asset} の sha256 を取得できません: '${digest}'" >&2
    exit 1
    ;;
esac
hash=$(nix hash convert --hash-algo sha256 --to sri "${digest#sha256:}")

# version と hash の 2 か所を書き換える。どちらかが 1 件に一致しなければ書き換えずに止める
for pattern in '^  version = ".*";$' '^    hash = ".*";$'; do
  hits=$(grep -c -- "$pattern" "$nixfile" || true)
  if [ "$hits" != 1 ]; then
    echo "default.nix で ${pattern} が ${hits} 件一致" >&2
    exit 1
  fi
done
sed -i '' \
  -e "s|^  version = \".*\";$|  version = \"${version}\";|" \
  -e "s|^    hash = \".*\";$|    hash = \"${hash}\";|" \
  "$nixfile"

# パッケージ単体をビルドして、ハッシュと実行ファイルが正しいかを確かめる（システムには適用しない）
echo "ビルド確認中..."
out=$(nix build --impure --no-link --print-out-paths --expr "
  (builtins.getFlake \"path:${flake}\").inputs.nixpkgs.legacyPackages.aarch64-darwin.callPackage ${here} { }
")
"$out/bin/omp" --version

echo "完了: omp ${version}。nxbd で差分確認 → nxs で適用 → omp --version"
echo "戻すとき: git -C \"${here}\" checkout -- ."
