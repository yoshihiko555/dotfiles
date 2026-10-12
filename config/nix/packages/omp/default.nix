{
  lib,
  stdenvNoCC,
  fetchurl,
}:
# oh-my-pi（omp）。pi のフォークで、Bun の単一バイナリとして配布されている。
# nixpkgs 未収録。公式 flake はソースからの全ビルドになるため、GitHub Releases の
# 公式バイナリをそのまま取得する。
#
# 更新手順:
#   1. nxu omp [version]  … update.sh が下の version・hash を書き換えて単体ビルドまで確認する
#      （version 省略時は latest）
#   2. nxbd で差分確認 → nxs で適用 → omp --version
let
  version = "18.10.2";
in
stdenvNoCC.mkDerivation {
  pname = "omp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-darwin-arm64";
    hash = "sha256-l1Lj1/e9q2NuIUlaav/Bluj/w6Lf+vUp2y3XPSveolU=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/omp"
    runHook postInstall
  '';

  # 実行ファイルの末尾に本体が埋め込まれているため、strip などの加工をしない
  dontFixup = true;

  meta = {
    description = "oh-my-pi（pi をベースにした全部入りのコーディングエージェント）";
    homepage = "https://omp.sh";
    license = lib.licenses.mit;
    mainProgram = "omp";
    platforms = [ "aarch64-darwin" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
