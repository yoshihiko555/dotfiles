{
  lib,
  buildNpmPackage,
  fetchurl,
  makeWrapper,
  nodejs,
}:
# Pencil 公式 CLI（@pen.dev/cli）。.pen のヘッドレス編集・保存・Export に使う。
# nixpkgs 未収録・公式 flake なしのため、npm registry から lockfile 経由で取得する。
# 本体は @pen.dev/cli だけに依存するラッパー package.json（update.sh で生成）の
# 依存として入れる。取得物は lockfile の integrity で検証される。
#
# ライセンスはプロプライエタリ（node_modules/@pen.dev/cli/LICENSE）。守るべき点:
#   - 改変禁止（2(a)）: パッチを当てない。npmConfigHook が node_modules 全体の
#     shebang を書き換えるため、本体だけは公開 tarball から展開し直して置く。strip もしない
#   - 再配布禁止（2(c)）: 公開バイナリキャッシュへ push しない。
#     リポジトリに置くのはこの式と package.json / lockfile（依存の URL とハッシュ）だけ
#
# 更新手順:
#   1. nxu pen [version]  … update.sh が lockfile を作り直し、下の version・hash・
#      npmDepsHash を書き換えて単体ビルドまで確認する（version 省略時は latest）
#   2. nxbd で差分確認 → nxs で適用 → pen version
let
  version = "0.3.10";

  # 改変のない本体。npm の公開 tarball そのもの
  pristine = fetchurl {
    url = "https://registry.npmjs.org/@pen.dev/cli/-/cli-${version}.tgz";
    hash = "sha512-TE7Pu8mcvnw06xKUmtUaeBAcGff30RfVYWCsQ4bGAtWanOhW5CUGF+3K+8GK/4FHfkiGQVXDfFQqxSPNUmAiHA==";
  };
in
buildNpmPackage {
  pname = "pen-cli";
  inherit version;

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./package.json
      ./package-lock.json
    ];
  };

  npmDepsHash = "sha256-jqyak8K8Zseqb6rMV7oFJalopNyOny3q3nh/1o6XgW8=";

  inherit nodejs; # engines: node >=22.19.0

  nativeBuildInputs = [ makeWrapper ];

  # 本体の dist は配布時点でビルド済み
  dontNpmBuild = true;
  # 依存の install スクリプト（sharp / esbuild 等）は動かさない。
  # ネイティブ部分は darwin-arm64 向けのビルド済みパッケージで揃っている
  npmFlags = [ "--ignore-scripts" ];
  # 依存の pi-coding-agent が npm-shrinkwrap.json を同梱しており、読み取り専用の
  # キャッシュのままだと npm ci が ENOTCACHED で失敗するため書き込み可能にする
  makeCacheWritable = true;

  # ラッパー自体は配布物ではないので、node_modules をそのまま置いて bin を張る
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/pen-cli $out/bin
    cp -R node_modules $out/lib/pen-cli/
    # shebang を書き換えられた本体を公開 tarball の中身に差し替える
    cli=$out/lib/pen-cli/node_modules/@pen.dev/cli
    rm -rf "$cli" && mkdir -p "$cli"
    tar xzf ${pristine} -C "$cli" --strip-components=1
    for bin in pen pencil; do
      makeWrapper ${lib.getExe nodejs} $out/bin/$bin \
        --add-flags $out/lib/pen-cli/node_modules/@pen.dev/cli/dist/index.mjs
    done
    runHook postInstall
  '';

  # installPhase 以降で本体を書き換えない（LICENSE 2(a)）。起動は wrapper が node を明示して行う。
  # 同梱のネイティブバイナリ（mcp-server / codex / claude）は署名済みのため strip もしない
  dontPatchShebangs = true;
  dontStrip = true;

  meta = {
    description = "Pencil 公式 CLI（.pen デザインファイルを操作する pen.dev エージェント）";
    homepage = "https://www.npmjs.com/package/@pen.dev/cli";
    license = lib.licenses.unfree;
    mainProgram = "pen";
    platforms = [ "aarch64-darwin" ];
  };
}
