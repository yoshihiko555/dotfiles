#!/usr/bin/env bash
# pen-cli（@pen.dev/cli）を指定バージョン（省略時は npm の latest）へ上げる。
#   使い方: ./update.sh [version]   … 通常は `nxu pen` から呼ぶ
# package.json / package-lock.json を作り直し、default.nix の version・hash・
# npmDepsHash を書き換えて、パッケージ単体のビルドで確認するまでを行う。
# 適用（nxs）はしない。
set -euo pipefail

pkg="@pen.dev/cli"
here=$(cd -- "$(dirname -- "$0")" && pwd)
flake=$(cd -- "$here/../.." && pwd)
nixfile="$here/default.nix"

version=${1:-$(npm view "$pkg" version)}
current=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$nixfile")
if [ -z "$current" ]; then
  echo "default.nix から現在の version を読めません" >&2
  exit 1
fi
if [ "$version" = "$current" ]; then
  echo "pen-cli は ${current} のままです（更新不要）"
  exit 0
fi
echo "pen-cli: ${current} → ${version}"

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# @pen.dev/cli だけに依存するラッパー。公開 tarball の package.json を直接使うと、
# 上流リポジトリ内のローカルパス（file:../../lib/*）を指す devDependencies が混ざる
cat >"$work/package.json" <<EOF
{
  "name": "pen-cli-wrapper",
  "private": true,
  "dependencies": {
    "${pkg}": "${version}"
  }
}
EOF
(cd "$work" && npm install --package-lock-only --ignore-scripts --no-audit --no-fund)

node - "$work/package-lock.json" "$here/package-lock.json" <<'EOF'
const fs = require("fs");
const { execFileSync } = require("child_process");
const [src, dst] = process.argv.slice(2);
const lock = JSON.parse(fs.readFileSync(src, "utf8"));

// darwin-arm64 以外のネイティブ依存を除く。codex / claude-agent-sdk は
// 1 プラットフォームあたり 200〜300MB あり、残すと fetchNpmDeps が全 OS 分を取得する
const ok = (list, want) =>
  !list || list.includes(want) || list.every((x) => x.startsWith("!") && x !== `!${want}`);
const dropped = Object.keys(lock.packages).filter((k) => {
  const p = lock.packages[k];
  return k !== "" && !(ok(p.os, "darwin") && ok(p.cpu, "arm64"));
});
for (const k of Object.keys(lock.packages)) {
  if (dropped.some((d) => k === d || k.startsWith(`${d}/node_modules/`))) delete lock.packages[k];
}
// 親エントリの optionalDependencies からも外す。残すと npm ci の整合チェックで
// 「lockfile に無い」と判定される
const droppedNames = new Set(
  dropped.map((k) => k.slice(k.lastIndexOf("node_modules/") + "node_modules/".length)),
);
for (const p of Object.values(lock.packages)) {
  if (!p.optionalDependencies) continue;
  for (const name of Object.keys(p.optionalDependencies)) {
    if (droppedNames.has(name)) delete p.optionalDependencies[name];
  }
  if (Object.keys(p.optionalDependencies).length === 0) delete p.optionalDependencies;
}
console.error(`dropped ${dropped.length} non darwin-arm64 packages`);

// npm が integrity を書かないエントリがあり、fetchNpmDeps が失敗するため registry から補う
for (const [k, p] of Object.entries(lock.packages)) {
  if (k === "" || p.link || p.integrity) continue;
  const name = k.slice(k.lastIndexOf("node_modules/") + "node_modules/".length);
  p.integrity = execFileSync("npm", ["view", `${name}@${p.version}`, "dist.integrity"], {
    encoding: "utf8",
  }).trim();
  if (!p.integrity) throw new Error(`integrity not found: ${name}@${p.version}`);
  console.error(`filled integrity: ${name}@${p.version}`);
}

fs.writeFileSync(dst, JSON.stringify(lock, null, 2) + "\n");
EOF

cp "$work/package.json" "$here/package.json"

# 本体 tarball の hash。fetchurl は SRI なら sha512 も受け付けるので、
# registry の dist.integrity をそのまま使えばダウンロードせずに済む
pristine_hash=$(npm view "${pkg}@${version}" dist.integrity)
# npmDepsHash は lock から計算する。fetchNpmDeps と同じ実装を使うため、
# flake.lock でピンした nixpkgs の prefetch-npm-deps を呼ぶ
deps_hash=$(nix run --inputs-from "$flake" nixpkgs#prefetch-npm-deps -- "$here/package-lock.json")

# default.nix の 3 か所を書き換える。どれかが 1 件に一致しなければ書き換えずに止める
node - "$nixfile" "$version" "$pristine_hash" "$deps_hash" <<'EOF'
const fs = require("fs");
const [file, version, pristineHash, depsHash] = process.argv.slice(2);
let src = fs.readFileSync(file, "utf8");
const rules = [
  [/^  version = ".*";$/m, `  version = "${version}";`],
  [/^    hash = ".*";$/m, `    hash = "${pristineHash}";`],
  [/^  npmDepsHash = ".*";$/m, `  npmDepsHash = "${depsHash}";`],
];
for (const [re, line] of rules) {
  const hits = src.match(new RegExp(re.source, "gm")) || [];
  if (hits.length !== 1) throw new Error(`default.nix で ${re} が ${hits.length} 件一致`);
  src = src.replace(re, line);
}
fs.writeFileSync(file, src);
EOF

# パッケージ単体をビルドしてハッシュの正しさを確かめる（システムには適用しない）。
# unfree の許可はホスト設定側にあるため、ここでは環境変数で一時的に許す
echo "ビルド確認中..."
NIXPKGS_ALLOW_UNFREE=1 nix build --impure --no-link --print-out-paths --expr "
  (builtins.getFlake \"path:${flake}\").inputs.nixpkgs.legacyPackages.aarch64-darwin.callPackage ${here} { }
"

echo "完了: pen-cli ${version}。nxbd で差分確認 → nxs で適用 → pen version"
echo "戻すとき: git -C \"${here}\" checkout -- ."
