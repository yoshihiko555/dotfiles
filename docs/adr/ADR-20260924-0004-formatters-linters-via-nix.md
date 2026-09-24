# ADR-20260924-0004: フォーマッタ・リンタの基準版を Nix に集約する

- ステータス: 採用
- 決定日: 2026-09-24
- 関連: [config/nix ADR-20260729-0002](../../config/nix/docs/adr/ADR-20260729-0002-multi-host-adoption.md)（言語ランタイム = mise、それ以外の CLI = Nix）

## 背景

ai-orchestra の CI（`facet-format`）は `prettier@3.9.6` で生成 Markdown を検査している。
ai-orchestra の hook は導入先に prettier が無いと PATH 上の `prettier` を使うが、
このマシンにはグローバルな prettier が無く、未整形の生成物が毎回差分になっていた。

調べると、フォーマッタ・リンタの置き場が揃っていなかった。

| ツール | 状態 |
|---|---|
| prettier | グローバルに無い。Zed は同梱の 3.9.9 |
| ruff / black | mise の Python に `pip install` されたもの（宣言外。Python の更新で消える） |
| stylua / goimports | 無い。conform.nvim の設定にはあり、LSP の整形で代用されていた |
| shfmt / nixfmt 等 | treefmt が dotfiles 内でだけ使う。PATH には無い |

## 選択肢

### A. prettier だけ mise で版を完全固定する

- CI の版と完全に一致させられる
- 「CLI は Nix」の境界から外れる例外になる。一度この形で入れた（`79d0333`）

### B. フォーマッタ・リンタを mise に集約する

- 版を個別に固定できるが、境界ルールの変更が要る。npm 系は mise の node に依存する

### C. フォーマッタ・リンタを Nix に集約する（採用）

- 境界ルールどおり。版は flake.lock で固定され、`nxu` で進む
- 版を個別には選べない。CI 側を nixpkgs の版に追従させる

## 決定

**C を採用する。**

1. 解決順は「プロジェクトのローカル版 → Nix の基準版」。基準版は `hosts/macbook/packages.nix` に置く
2. CI が版を固定しているプロジェクト（ai-orchestra）は、CI 側を Nix の版に合わせる。
   `nxu` の後は `nix eval --raw --inputs-from config/nix nixpkgs#prettier.version` で版を確認する
3. リンターは単体で動くもの（ruff / shellcheck / actionlint / golangci-lint）だけ
   グローバルに置く。設定やプラグインに依存するもの（eslint / markdownlint-cli2 等）はプロジェクトのローカル版だけを使う
4. prettierd は使わない。ローカル版が無いと同梱の prettier を使い、基準版と揃わない
5. エディタも同じ解決順にする
   - Neovim: conform.nvim が `node_modules/.bin` → PATH の順で探す。prettier の対象に
     json / jsonc / yaml / markdown / css / html を加える
   - Neovim の ts/js リント: nvim-lint は、ファイルから上へ辿って eslint の設定と
     `node_modules/.bin/eslint` の両方が見つかったときだけ、設定のあるディレクトリで eslint を動かす
   - Neovim の nix / sh / yaml / toml: dotfiles 内は treefmt（`dotfiles-treefmt --stdin`）で整形し、
     対象・除外・オプションを `treefmt.nix` の 1 か所に揃える。dotfiles 外は nixfmt / shfmt / prettier / taplo を直接使う
   - Neovim のリント: sh / bash は shellcheck、zsh は `zsh -n`、`.github/workflows/` の yaml は actionlint
   - Zed: 同梱の prettier を無効にし、外部フォーマッタに `prettier-local-first`
     （`packages/prettier-local-first.nix`）を使う

### 入れないもの

- eslint_d: eslint の設定が無いリポジトリでは、nvim-lint が ESLint 9 のエラー出力を解析できず、
  1 行目にエラーを出す。eslint はプロジェクトのローカル版だけを使う（決定 3・5）。
  `node_modules/.bin/eslint` は間接依存でも置かれるため、設定ファイルの有無も条件にする
- markdownlint-cli2: 一度グローバルに入れたが、ルールを決める設定ファイルが前提で、設定を持つリポジトリが無く
  どこからも使われていなかった（2026-09-25 に外した）。Markdown の整形は prettier が担う

## 影響

- mise から `npm:prettier` を外す（`79d0333` を置き換える）
- mise の Python に入っていた ruff / black を削除する。ruff は Nix 版（0.16.4）に替わり、
  black は conform で ruff の代わりにしか使われないため置き換えない
- stylua の導入で nvim の lua 整形が lua_ls から stylua に替わる。既存の lua は一度まとめて整形する
- Neovim で md を保存すると prettier で整形される（treefmt の md 除外は `task nix-fmt` の範囲の話で、これとは別）
- dotfiles 内の nix / sh / yaml / toml は Neovim でも treefmt を通すため、保存時整形と pre-commit の結果が一致する。
  拡張子の無いスクリプトや `codex/config.toml` など treefmt の対象外は、保存しても整形されない
- `node_modules` が未インストールのリポジトリ（tech-site 等）では Nix 版で整形される
- Zed の Java は同梱 prettier のプラグインに頼るため対象外。同梱 prettier のディレクトリは Zed が管理するので残る
- hermes には入れない（[config/nix ADR-20260801-0004](../../config/nix/docs/adr/ADR-20260801-0004-module-layer-design.md) ルール 3）。使い始めたら `home/packages.nix` へ昇格する
