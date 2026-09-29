#!/usr/bin/env bash
# pen-cli（@pen.dev/cli）の package.json / package-lock.json を指定バージョンで作り直す。
#   使い方: ./update.sh 0.3.10
# 実行後、default.nix の version と npmDepsHash を更新する（手順は default.nix 冒頭）。
set -euo pipefail

version=${1:?usage: update.sh <version>}
here=$(cd -- "$(dirname -- "$0")" && pwd)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# @pen.dev/cli だけに依存するラッパー。公開 tarball の package.json を直接使うと、
# 上流リポジトリ内のローカルパス（file:../../lib/*）を指す devDependencies が混ざる
cat >"$work/package.json" <<EOF
{
  "name": "pen-cli-wrapper",
  "private": true,
  "dependencies": {
    "@pen.dev/cli": "${version}"
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
