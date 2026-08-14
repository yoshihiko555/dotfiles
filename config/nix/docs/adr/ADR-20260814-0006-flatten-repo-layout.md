# ADR-20260814-0006: リポジトリのディレクトリ構成をフラット化（stow 由来の中間層を除去）

- ステータス: 採用
- 決定日: 2026-08-14
- 関連: [ADR-20260424-0001](ADR-20260424-0001-nix-layout.md)（Nix 設定の集約先。
  具体パス `config/.config/nix/` → `config/nix/` は本 ADR で変更するが、
  「Nix 設定を `config/` 配下に集約する」という決定自体は変更しない） /
  [ADR-20260801-0004](ADR-20260801-0004-module-layer-design.md)（Nix 内部の
  `darwin/` / `home/` / `hosts/` 層設計。本 ADR の対象外）

## 背景

stow は 2026-08-07 に廃止済みだが、`<pkg>/.<dotfile>` というディレクトリ命名
（`claude/.claude/`、`config/.config/`、`shell/.zshrc` 等）だけが残っていた。
配線は home-manager の `mkOutOfStoreSymlink`（`mkLink`）による明示パス文字列指定であり、
**リポジトリのレイアウトは `$HOME` のレイアウトから完全に独立している**。つまりこの命名規則は
もはや何の機能も持たない「死んだ規約」であり、パスを 1 段深くしているだけだった。

参考にしたのは [mozumasu/dotfiles](https://github.com/mozumasu/dotfiles) だが、
採用したのはディレクトリの形ではない（詳細は「選択肢」参照）。

## 選択肢

### A. 現状維持（`<pkg>/.<dotfile>` のまま）

- 変更コストはゼロ
- しかし stow を廃止した以上、この命名は何の配線にも使われていない。
  新しいファイルを追加するたびに「なぜここだけ 1 段深いのか」を説明できない状態が固定化する

### B. `$HOME` ミラー型（mozumasu 型、不採用）

mozumasu は「リポジトリ直下が `$HOME` のミラー」（`.config/`、`.claude/` が
リポジトリ直下にある）方式。これを採らなかった理由:

- リポジトリ直下には既に `.claude/settings.local.json`（このリポジトリ自身を
  Claude Code で開いたときのプロジェクト設定）が存在し、配布物としての `.claude/` と
  同居して極めて紛らわしくなる

また mozumasu の Nix 内部構成（`darwin/` と `home-manager/` をフラットに並べる）も
採用しない。当リポジトリの `darwin/` / `home/` / `hosts/` / `modules/` の層分割は
[ADR-0004](ADR-20260801-0004-module-layer-design.md) で決めたもので、そちらの方が
整理されている。mozumasu から取り込む価値があるのは形ではなく機能
（sops-nix による秘密管理、`hostSpec.isWork` による work/personal 分岐、
`nix run .#switch` 等の flake apps による Taskfile 代替）であり、**これらは今回スコープ外**。

### C. 中間層を除去してフラット化（採用）

- `<pkg>/.<dotfile>/...` → `<pkg>/...` にパスを 1 段縮める
- `$HOME` のミラーは作らない。リポジトリ直下は当リポジトリ自身の管理用ファイル
  （`.claude/settings.local.json`、`AGENTS.md` 等）専用のまま保つ
- `config/nix` の Nix 内部構成（`darwin/` / `home/` / `hosts/` / `modules/`）は
  ADR-0004 のまま変更しない

## 決定

**C を採用。** 実施は 5 フェーズに分割した。

| Phase | 内容 | コミット |
|---|---|---|
| 0 | 棚卸し（`.stow-global-ignore` 削除、README/GUIDE の記述ずれ修正） | `140359a` |
| 1 | `claude/.claude/*` → `claude/*`、`codex/`、`gemini/`、`takt/` も同様 | `0af1054` |
| 2 | `editorconfig/.editorconfig` → `home/editorconfig` | `7f901a9` |
| 3 | `config/.config/<app>` → `config/<app>`（nix 含む 15 個） | `c038d4a` |
| 4 | `shell/.zshrc` 等 → `shell/zshrc` 等、`shell/.zsh/` → `shell/zsh/` | `7c25596` |

### フェーズ分割の理由

hermes への影響範囲でフェーズの順序を決めた。hermes が消費するのは
`shell/` と `config/{starship,git,mise,nvim,tmux,nix}` のみ（[home/dotfiles.nix](../../home/dotfiles.nix)）
なので、macbook 専用のもの（Claude/Codex/Gemini/takt/alfred 関連）を先に動かし、
hermes に影響する変更（`shell/`、`config/`）を後段に回した。1 フェーズ = 1 コミットとし、
`nix build` で各段階の破壊がないことを確認しながら進めた。

### `config/nix` の位置は維持

flake の位置は `config/nix` に維持し、リポジトリルートへは移さない。

- `~/.config/nix` への自己リンクが `nix.conf` を含むディレクトリを必要とする
- [BOOTSTRAP.md](../BOOTSTRAP.md) が現行パス前提で正典化されたばかりである

## 影響

- CI（[.github/workflows/nix-check.yml](../../../../.github/workflows/nix-check.yml)）と
  `config/nix/treefmt.nix` の excludes もパスを追随させる必要があった。
  特に treefmt の excludes は、古いままだとアプリが書き戻す
  `codex/config.toml` / `config/mise/config.toml` / `config/gh/config.yml` が
  整形対象に入り、次回アプリ起動で書き戻されて CI が理由なく赤くなるという
  静かな壊れ方をする
- skills の相対シンボリックリンク（23 件）は階層が 1 段浅くなったため深さを再計算した
  （`claude`/`codex` は `../../../` → `../../`、`gemini/config/skills` は
  `../../../../` → `../../../`）
- ルート [README.md](../../../../README.md) のディレクトリツリー表記を実態に合わせて
  更新した（本 ADR と同一コミット）。[config/nix/README.md](../../README.md) /
  [GUIDE.md](../GUIDE.md) / [BOOTSTRAP.md](../BOOTSTRAP.md) / [CHEATSHEET.md](../CHEATSHEET.md)
  は確認した結果、既に現行パスで記述済みのため変更なし
- **hermes はこの ADR 作成時点でまだ switch していない。** macbook のみ適用・動作確認済み。
  hermes への反映は次回 `git pull` + `switch` 時に行う

  > **追記（2026-08-14）**: hermes にも `darwin-rebuild switch` を適用済み。
  > 全配線の解決と、LLM デーモン（miniserve / llama-swap / gateway）の稼働継続を確認した。
  > 下記「未確定事項」の 1 件目（配線の確認）はこれにより解消。
  > 詳細は [ROADMAP.md](../ROADMAP.md)（`7fc08ae`）を参照。

## 未確定事項（将来の ADR で扱う）

- hermes への反映後、`shell/` / `config/{starship,git,mise,nvim,tmux,nix}` の配線が
  想定どおり解決することの確認（未switchのため未検証）
- mozumasu から機能面で取り込む価値がある要素（sops-nix、`hostSpec.isWork`、
  flake apps による Taskfile 代替）の採否は今回スコープ外のまま。着手する場合は
  別途 ADR で扱う
