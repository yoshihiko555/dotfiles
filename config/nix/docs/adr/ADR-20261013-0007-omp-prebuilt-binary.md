# ADR-20261013-0007: oh-my-pi（omp）は公式 flake ではなく公式バイナリを自前パッケージで取得する

- ステータス: 採用
- 決定日: 2026-10-13
- 関連: [PHASE-3-2-CLI-INVENTORY.md](../PHASE-3-2-CLI-INVENTORY.md) 5 章
  （「nixpkgs 未収録でも公式 flake があれば flake input で宣言する」。本 ADR はその例外） /
  [ADR-20260801-0004](ADR-20260801-0004-module-layer-design.md)（ルール 3: まず使うホストの
  `hosts/macbook/` に置く）

## 背景

pi（nixpkgs の `pi-coding-agent`）の試用にあわせて、比較用に pi のフォークである
oh-my-pi（コマンド名 `omp`）も入れることにした。omp は nixpkgs 未収録だが、公式 flake
（`github:can1357/oh-my-pi`）と home-manager モジュール（`programs.omp`）を持つ。
既存方針に従えば、takt と同じく flake input で宣言することになる。

しかし公式 flake にはビルド済みのキャッシュがない。flake の `nixConfig` は nix-community の
cachix を指しているが omp は置かれておらず、そもそも input として取り込んだ flake の
`nixConfig` は使われない。`nix build --dry-run` で見積もった規模は次のとおり
（2026-10-12、`c891346` 時点）。

- 手元でのビルド 2,249 件（Rust の crate 約 480、Bun のパッケージ 583 ほか）
- ダウンロード 730.6 MiB、展開後 3.4 GiB（Rust nightly ツールチェーン、clang / LLVM 21、
  Bun、Zig、macOS SDK、flake が独自に固定している nixpkgs）

omp は 2026-10-12 の 1 日だけで 3 回リリースしており、更新のたびにこの規模のビルドが走る。

## 選択肢

### A. 公式 flake を input にする（既存方針どおり、不採用）

- home-manager モジュールで設定まで宣言できる
- 上記の手元ビルドが更新ごとに発生する。試用段階の比較用ツールに払うコストとして見合わない

### B. Homebrew の tap（不採用）

- `homebrew.taps` / `homebrew.brews` に 2 行で済む（herdr と同じ形）。中身は公式バイナリで、
  formula に sha256 が記録されている
- 版がリポジトリに固定されず、`bxu` という Nix とは別の経路で更新される。`nxrb` で戻せない

### C. mise の github backend（不採用）

- 試用ではこれで入れた（mise の設定には宣言せず `mise install` のみ）
- 言語ランタイム以外の CLI を mise に置くのは境界違反
  （[PHASE-3-2-CLI-INVENTORY.md](../PHASE-3-2-CLI-INVENTORY.md) 2 章）

### D. 自前パッケージで公式バイナリを取得する（採用）

- GitHub Releases の `omp-darwin-arm64` を、版とハッシュを固定して `fetchurl` し、
  `$out/bin/omp` に置くだけ
- pen-cli と同じく `update.sh` を持ち、`nxu omp [version]` で更新できる。ハッシュは GitHub が
  記録しているアセットの sha256 から作るので、更新時に余分なダウンロードをしない

## 決定

**D を採用。** [packages/omp/](../../packages/omp/default.nix)（`default.nix` と `update.sh`）を追加し、
`hosts/macbook/packages.nix` で宣言した（macbook のみ）。

- 実行ファイルは Bun の単一バイナリで、末尾に本体が埋め込まれている。`dontFixup = true` で
  strip などの加工をしない。ビルド後も開発元の署名（TeamIdentifier `VTLHGQC72S`）が
  有効なことを確認した
- `update.sh` は、18.10.1 への引き下げと 18.10.2 への復帰、更新が不要なときの判定を確認した
- switch 後、`omp --version` が `omp/18.10.2` を返すことを確認した

## 影響

- 版とハッシュがリポジトリに固定される。更新は `nxu omp` → `nxbd` → `nxs`、戻すのは `nxrb` で、
  他の Nix 管理パッケージと同じ流れに乗る
- 「公式 flake があれば flake input」は原則として維持する。例外にする条件は
  「公式 flake にキャッシュがなく、手元ビルドが重い」こと
- 設定と認証情報（`~/.omp/agent/`）は Nix の管理外。dotfiles で管理する場合も、
  ディレクトリを丸ごと張らず、必要なファイルだけを配る
- 撤回するときは `packages/omp/` と `packages.nix` の宣言を消して `nxs` し、`~/.omp` を削除する

## 未確定事項（将来の ADR で扱う）

- nixpkgs に収録されたら nixpkgs の版へ、公式 flake にキャッシュが用意されたら
  flake input（設定も home-manager モジュールで宣言）への移行を検討する
- 試用の結果、omp を残すか、pi に一本化するかは未定
