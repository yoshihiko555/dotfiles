# treefmt-nix の設定。
#
# ADR-20260730-0003 で一度は削ぎ落とした treefmt-nix を、Phase 4-3
# （nix flake check + CI）で復元する（ROADMAP.md 4-3節）。
#
# 適用範囲は nix + shell + yaml/toml のみ（決定済み方針）。
# lua / markdown / json は対象外。config/ 配下に nvim の設定
# （lua / md / json）が同居しており、巻き込むと巨大差分になるため。
{ lib, ... }:
{
  # プロジェクトルートの探索起点。.git/config はリポジトリ直下にあるため、
  # flake.nix はサブディレクトリ（config/nix）にあっても、
  # ここを起点に上方向へ探索すれば常にリポジトリ全体が対象になる。
  #
  # ただし `nix flake check` の checks.formatting は self（このディレクトリ
  # 以下のみ）をコピーした先で完結するため、実質 config/nix 配下
  # のみが検査対象になる（flake が repo ルートではなくサブディレクトリに
  # あることに起因する制約。詳細は flake.nix のコメント参照）。
  projectRootFile = ".git/config";

  programs.nixfmt.enable = true;

  programs.shfmt = {
    enable = true;
    # .editorconfig（home/editorconfig）はリポジトリ直下に無く
    # CI からは参照できないため、useEditorConfig には頼らず明示指定する
    # （indent 2 は .editorconfig の [*] 既定値と揃えている）
    indent_size = 2;
    # shfmt のデフォルトは simplify = true（`-s`）で、[[ ]] 内の不要な
    # クォートを取り除くなど整形の範囲を超えた書き換えを行う
    # （挙動は変わらないが「整形以外の意味的変更を混ぜない」方針に反するため無効化）
    simplify = false;
  };

  # shfmt には indent_size / simplify 以外のオプションが programs.shfmt
  # から公開されていないため、既存コードスタイルに合わせるフラグは
  # settings.formatter 経由で直接注入する（programs.shfmt モジュールが
  # 積む -w/-i と mkAfter でマージされる）。
  #   -ci: switch の case を1段字下げする（既存の case ブロックの書き方）
  #   -bn: `&&` / `|` を行頭に置く継続行スタイルを維持する
  #        （既存の `&&`/`|` 継続はリポジトリ内で確認できた 6 件全てが行頭型で
  #        行末型は 0 件。shfmt の既定は行末型のため明示的に上書きする）
  #
  # -kp（手動の桁揃えスペースを保持）は aerospace layouts の
  # `move_app_to_workspace 'id' 'M1'` のような引数列の桁揃えを守るために
  # 検討したが不採用。-kp は「桁揃え」と「単なるインデント」を区別できず、
  # -bn によるパイプ再構成後の while ブロックや、複数行に展開された
  # `{ ...; }` ブロック（shared/skills/.../export.sh）で明らかに壊れた
  # 出力（本来 2 段のインデントが 20 列を超える、閉じ `done`/中身の桁が
  # ずれる等）を生んだ。aerospace の5行の桁揃えが失われる方が、
  # 無関係な複数ファイルで壊れた見た目になるより実害が小さいと判断した
  #
  # -sr（リダイレクト演算子の後にスペース）は当初検討したが不採用。
  # このリポジトリの実際の慣習を数えると、`> "$file"` のような引用符付き
  # ターゲットへのリダイレクトはスペースありが多数派（16/18）な一方、
  # `2>/dev/null` 系のリテラルパスへのリダイレクトはスペースなしが
  # 全会一致（19/19）、ヒアドキュメント区切り記号も全会一致でスペースなし
  # （2/2）。-sr はターゲットの種類を区別できない一律オプションのため、
  # 有効化すると多数派16件を直すために全会一致の21件を崩すことになり、
  # 総体としては無効化した方がリポジトリの既存スタイルをより多く保持できる
  settings.formatter.shfmt.options = lib.mkAfter [
    "-ci"
    "-bn"
  ];

  programs.yamlfmt = {
    enable = true;
    # yamlfmt の既定は空行をすべて詰める。既存ファイルの意図的な空行区切り
    # （taskfiles のタスク間区切りなど）を潰さないよう保持する
    settings.formatter.retain_line_breaks = true;
  };

  programs.taplo = {
    enable = true;
    settings = {
      formatting = {
        # 既定 true。行末コメントを桁揃えすると starship.toml のような
        # 短いキー・長いコメント混在ファイルで可読性が落ちるため無効化
        align_comments = false;
        # 既定 true。単一要素・短い配列まで複数行へ展開されて
        # aerospace.toml 等の既存スタイル（1行の配列）を壊すため無効化
        array_auto_expand = false;
      };
    };
  };

  settings.excludes = [
    # 対象外の拡張子（決定済み方針）
    "*.lua"
    "*.md"
    "*.markdown"
    "*.json"

    # vendored / 生成物。.gitignore 済みで treefmt の git walk では
    # 元々スキャン対象外だが、意図を明示するためここにも書いておく
    "config/tmux/plugins/**"
    "codex/skills/.system/**"
    "shared/skills/codex-only/.system/**"
    "takt/runtime.yaml"

    # ROADMAP.md（Phase 3-2, l.328-329, l.419）記載の「アプリが書き戻す
    # 要注意 5 件」。home-manager の mkOutOfStoreSymlink でリポジトリ内の
    # ファイルへ直接シンボリックリンクしているため、アプリの通常動作
    # （設定変更・キャッシュ更新）がそのままリポジトリを書き換える。
    # 整形しても次のアプリ起動で崩れ、CI が理由もなく赤くなるため除外する。
    #   - karabiner.json / lazy-lock.json → 拡張子 *.json exclude で既にカバー済み
    #   - flake.lock → enableDefaultExcludes の "*.lock" で既にカバー済み
    #   - 以下2件は toml/yaml のため個別に除外が必要
    "codex/config.toml"
    "config/mise/config.toml"
    # gh 自身が書き込む設定ファイル（上記5件と同じ理由で追加）
    "config/gh/config.yml"

    # sops で暗号化した秘匿ファイル（Phase 4-5）。yamlfmt によるインデント・
    # 改行の書き換えで暗号値のバイト列に予期しない影響が出るのを避けるため、
    # フォーマッタの対象から外す（内容は sops 自身の出力レイアウトを正とする）
    "config/nix/secrets/**"

    # 引数列を意図的に桁揃えしているファイル。
    # `move_app_to_workspace 'com.google.Chrome'  'M1'` のように
    # ワークスペース名を縦に揃えることで、どのアプリがどの画面へ
    # 割り当たるかを一覧できるようにしてある。shfmt はこの桁揃えを
    # 単一スペースへ潰してしまい（-kp は上記のとおり副作用が大きく不採用）、
    # 整形の利得より可読性の損失が上回るため除外する
    "config/aerospace/layouts/*.sh"
  ];
}
