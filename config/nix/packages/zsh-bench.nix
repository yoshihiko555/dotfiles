{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
# 対話 zsh のレイテンシ計測（romkatv/zsh-bench）。nixpkgs 未収録。
# 本体は自分の位置（${ZSH_SCRIPT:A:h}）から internal/ を読むため、ツリーごと share に置く。
# 計測対象は実行時 PATH 上の zsh なので、shebang も書き換えずに env の zsh を使う。
stdenvNoCC.mkDerivation {
  pname = "zsh-bench";
  version = "0-unstable-2026-04-27";

  src = fetchFromGitHub {
    owner = "romkatv";
    repo = "zsh-bench";
    rev = "28b1b1bc888159f0a2cf50f9d29381758341aba1";
    hash = "sha256-dsHGpDTweDqJdLhO/9th2kDt56crfjqkTKBilEi9RaY=";
  };

  dontBuild = true;
  dontPatchShebangs = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/zsh-bench $out/bin
    cp -r . $out/share/zsh-bench/
    ln -s $out/share/zsh-bench/zsh-bench $out/bin/zsh-bench
    runHook postInstall
  '';

  meta = {
    description = "Benchmark for interactive Zsh";
    homepage = "https://github.com/romkatv/zsh-bench";
    license = lib.licenses.mit;
    mainProgram = "zsh-bench";
    platforms = lib.platforms.unix;
  };
}
