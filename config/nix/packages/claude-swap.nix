{
  lib,
  fetchFromGitHub,
  ps,
  python3Packages,
}:
python3Packages.buildPythonApplication rec {
  pname = "claude-swap";
  version = "0.28.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "realiti4";
    repo = "claude-swap";
    tag = "v${version}";
    hash = "sha256-hg8Dlhsea/crMxVJCdTKOPNMAH/JJxnXG6MEgKGg6n4=";
  };

  build-system = [ python3Packages.hatchling ];

  # 実行用 Python と依存ライブラリは Nix 内で完結させる。
  # 開発用の mise Python や uv tool の環境には依存しない。
  dependencies = with python3Packages; [
    textual
    truststore
  ];

  # 実プロセスの起動時刻を ps で読むテストがあるため、ビルド環境にも ps を置く。
  nativeCheckInputs =
    (with python3Packages; [
      pytestCheckHook
      pytest-asyncio
      pytest-xdist
    ])
    ++ [ ps ];

  # 上流の -n auto を解除し、並列数は Nix の割り当てに従う。
  pytestFlags = [
    "-o"
    "addopts="
  ];

  pythonImportsCheck = [ "claude_swap" ];

  meta = {
    description = "Claude Code の複数アカウントと利用状況を管理する CLI";
    homepage = "https://github.com/realiti4/claude-swap";
    license = lib.licenses.mit;
    mainProgram = "cswap";
    platforms = lib.platforms.darwin ++ lib.platforms.linux;
  };
}
