{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  writeShellApplication,
}:
# 対話 zsh のレイテンシ計測（romkatv/zsh-bench）。nixpkgs 未収録。
# 本体は自分の位置（${ZSH_SCRIPT:A:h}）から internal/ を読むため、ツリーごと share に置く。
let
  upstream = stdenvNoCC.mkDerivation {
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
      mkdir -p $out/share/zsh-bench
      cp -r . $out/share/zsh-bench/
      runHook postInstall
    '';
  };
in
# 本体は PATH 上の zsh を計測するため、普段使いの /bin/zsh を先頭に置いて起動する。
# 本体自身も zsh スクリプトなので、-f で ~/.zshenv による PATH の組み直しを避ける。
writeShellApplication {
  name = "zsh-bench";
  text = ''
    shim=$(mktemp -d)
    trap 'rm -rf "$shim"' EXIT
    ln -s /bin/zsh "$shim/zsh"
    PATH="$shim:$PATH" /bin/zsh -f ${upstream}/share/zsh-bench/zsh-bench "$@"
  '';

  meta = {
    description = "Benchmark for interactive Zsh (measures /bin/zsh)";
    homepage = "https://github.com/romkatv/zsh-bench";
    license = lib.licenses.mit;
    mainProgram = "zsh-bench";
    platforms = lib.platforms.darwin;
  };
}
