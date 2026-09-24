{
  writeShellApplication,
  coreutils,
  prettier,
}:
# Zed の外部フォーマッタから呼ぶ prettier。
# 対象ファイルから上位へ node_modules/.bin/prettier を探し、あればそれを、
# 無ければ Nix の prettier を使う（conform.nvim と同じ解決順）。
writeShellApplication {
  name = "prettier-local-first";
  runtimeInputs = [
    coreutils
    prettier
  ];
  text = ''
    file=""
    prev=""
    for arg in "$@"; do
      if [[ $prev == --stdin-filepath ]]; then
        file=$arg
      fi
      prev=$arg
    done

    dir=$(dirname -- "''${file:-$PWD/-}")
    while true; do
      if [[ -x "$dir/node_modules/.bin/prettier" ]]; then
        exec "$dir/node_modules/.bin/prettier" "$@"
      fi
      parent=$(dirname -- "$dir")
      [[ $parent == "$dir" ]] && break
      dir=$parent
    done

    exec prettier "$@"
  '';
}
