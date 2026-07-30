# Nix 移行ロードマップ

dotfiles を段階的に Nix 管理へ寄せていくための計画。
Nix の学習度合いに合わせて、小さく動かしながら進める。

方針・目的の根拠は [ADR-20260730-0003](adr/ADR-20260730-0003-purpose-and-order.md)。

---

## 目的

| 優先 | 目的 |
|---|---|
| 1 | **環境依存の切り分けを宣言的に表現する**（ヘッドレスな hermes に GUI cask を乗せない等） |
| 2 | **新端末で環境を引き継げるようにする**（現状 8 手順・順序が暗黙 → 1 コマンドへ） |
| 3 | 複数マシンで同一環境を構築する |

### 目的から外したもの

これを明示しておくのは、スコープが膨らんで停滞するのを防ぐため。

- スキル管理の宣言化（現状で困っていない）
- devShell + direnv（mise と重複）
- zsh 起動最適化（実測 0.244 秒で十分速い）
- launchd の宣言管理（自己管理対象が `cliproxyapi` の 1 つだけ）

---

## 前提: 管理対象ホスト

| ホスト | system | 用途 | Nix の適用範囲 |
|---|---|---|---|
| MacBook Pro | `aarch64-darwin` | **メイン開発機**（現在の主戦場） | CLI + dotfiles。GUI アプリ本体は brew cask |
| Mac mini (hermes, M4) | `aarch64-darwin` | Hermes Agent 運用。**ヘッドレス** | ほぼ全体。cask は乗せない |
| 会社 Windows (WSL2) | `x86_64-linux` | **予備機**。現状稼働プロジェクトなし | WSL2 内部のみ。Windows 本体は対象外 |

> WSL2 は当初「日常的に開発している」と判断していたが、実態は予備機だった。
> 詳細と経緯は ADR-20260730-0003 を参照。

---

## ステータス凡例

| 記号 | 意味 |
|---|---|
| `[x]` | 完了 |
| `[~]` | 進行中 |
| `[ ]` | 未着手 |
| `[-]` | 対象外（判断済み。記録として残す） |
| `[?]` | 条件付き（トリガー待ち） |

---

## Phase 0: 基盤セットアップ — `[x]` 完了（2026-04-24）

- [x] `config/.config/nix/` にディレクトリ集約（stow 経由で `~/.config/nix/` にリンク）
- [x] `flake.nix`（最小の devShell 定義）
- [x] `nix.conf` で `experimental-features = nix-command flakes` を有効化
- [x] `shell/.zprofile` で login shell でも Nix を初期化
- [x] ドキュメント（ROADMAP / ADR）を `docs/` 配下に整備

**完了条件**: `nix develop ~/.config/nix` でサンドボックス shell が起動する → 達成

---

## Phase 1: CLI ツール単体を nix profile で試す — `[-]` 対象外（スキップ）

> **2026-07-29 判断: スキップ。**
> 候補ツール（`fd` / `bat` / `eza` / `dust` / `procs`）はいずれも brew で導入でき、
> 実利がなく学習目的にとどまる。Phase 3 で同じ学習が実務と同時に得られる。
> 当初計画の記録として残す。

---

## Phase 2: プロジェクト用 devShell を拡張 — `[-]` 対象外

> **2026-07-30 判断: 対象外。**
> mise がプロジェクト単位のランタイム切替を担っており、役割が重複する。
> mise を残す方針（下記「共存方針」）のため、devShell / direnv に価値が出ない。
> 当初計画の記録として残す。
>
> 再検討のトリガー: mise で賄えないツール（protoc / terraform / LSP 群など）の
> バージョン差異がプロジェクト間で問題になった場合。

---

## Phase 3: nix-darwin + home-manager 導入 — `[~]` 現在地

3 ホストを 1 つの flake で宣言的に管理する。**nix-darwin を最初から使う**
（理由は `homebrew.onActivation.cleanup = "zap"` による腐敗の構造的防止）。

### 目標構成

```
config/.config/nix/
├── flake.nix              # darwinConfigurations + homeConfigurations の 2 系統
├── hosts/
│   ├── common/            # 3 台共通（+ homebrew-personal / homebrew-work の分離）
│   ├── macbook/
│   ├── hermes/
│   └── wsl/               # standalone home-manager
├── home/
│   ├── dotfiles.nix       # mkOutOfStoreSymlink による配線
│   ├── darwin.nix
│   └── linux.nix
├── modules/
├── packages/              # nixpkgs に無いツールの自作パッケージ
└── docs/
```

`shared/agents/` の core + diff と同じ構造。

### 方式

- 原則 **`mkOutOfStoreSymlink`**（編集が即反映される。stow と同じ挙動）
- **「原則 + 例外」**とする。循環参照の罠やアプリが書き込むファイルには
  `home.activation` を使い、**例外の理由をコメントに残す**
- 設定内容を Nix 言語で書き直す（`programs.*` への全面移行）方針は採らない

### Phase 3-0: 着手前の前提作業 — `[ ]`

`shell/.zshrc` の移植阻害要因を修正する。**Nix と無関係に価値がある改善。**

- [ ] `eval "$(sheldon source)"` に `command -v` ガードを追加
- [ ] `eval "$(zoxide init zsh)"` に `command -v` ガードを追加
- [ ] `eval "$(git gtr init zsh)"` に `command -v` ガードを追加（Linux 対応は要確認）
- [ ] `eval "$(starship init zsh)"` に `command -v` ガードを追加
- [ ] `. "$HOME/.local/bin/env"` に存在チェックを追加
- [ ] `/Users/yoshihiko/.bun/_bun` の絶対パスを `~/.zshrc.local` へ退避
- [ ] `claude-mem` alias の絶対パスを `~/.zshrc.local` へ退避
- [ ] `aliases.zsh` の `ls -G` を `$OSTYPE` で分岐（GNU は `--color=auto`）
- [ ] `aliases.zsh` の Dia 依存 alias（`trend` / `daily` / `weekly`）を `$OSTYPE` で分岐
- [ ] dotfiles の絶対パス直書きを変数に集約

**参考**: `hermes/home/.zsh/hermes-helpers.zsh` に**正しくガードが入った実装が既にある**。
本体へ還流させる形になる。

**完了条件**: `.zshrc` が Linux でエラーなく起動する（WSL2 で検証可能な状態になる）。

### Phase 3-1: hermes（Mac mini）— `[ ]` 最初の着手対象

macOS のため学習が MacBook Pro に転用でき、ヘッドレスで GUI 移行の考慮が不要。
メイン機ではないため壊れても業務が止まらない。

- [ ] `flake.nix` を multi-host 構造へ拡張（mozumasu の構造をコピーして削る）
- [ ] `hosts/common/` に 3 台共通のパッケージ・設定を定義
- [ ] `hosts/hermes/` を定義。**cask を 1 つも書かない**（＝ヘッドレスの宣言）
- [ ] `home/dotfiles.nix` で `mkOutOfStoreSymlink` の配線を書く
- [ ] `homebrew.brews` に `hermes/Brewfile` の 18 個を移す
- [ ] `homebrew.onActivation.cleanup = "zap"` を有効化
- [ ] `darwin-rebuild switch --flake .#hermes` で適用
- [ ] `scripts/install-hermes-subset.sh` が不要になったことを確認
- [ ] `hermes/Brewfile` / `hermes/home/` の重複解消（削除の可否は別途判断）

**完了条件**:
1. `darwin-rebuild switch --flake .#hermes` 一発で hermes の環境が再現できる
2. `install-hermes-subset.sh` を使わずに済む
3. cask が 1 つも入っていない（環境切り分けが宣言で機能している）

### Phase 3-2: MacBook Pro — `[ ]`

既に動いている環境のため最もリスクが高い。**hermes で手応えを得てから着手する。**

- [ ] アプリが書き込むファイルの**除外リスト**を確定（`~/.claude/settings.json` 等）
- [ ] 復旧手段を用意（別シェルの確保、リカバリ手順の文書化）
- [ ] `hosts/macbook/` を定義。GUI cask 13 個はここに置く
- [ ] `homebrew-personal.nix` / `homebrew-work.nix` の分離を検討
- [ ] `~/.config/nvim-dev` の手動リンク（worktree 参照）の扱いを決める
- [ ] stow から home-manager へ段階移行（パッケージ単位）
- [ ] `taskfiles/link.yml` / `Makefile` の link ターゲットを撤去
- [x] `config/.config/wezterm.bak`（17 ファイル）の腐敗を解消 — 2026-07-30 に削除（Nix 待ちせず先行対応）
- [x] `taskfiles/link.yml` の `link-tmux` / `restow-tmux`（存在しないパッケージ参照）を解消 — 2026-07-30 に撤去（Nix 待ちせず先行対応）

**完了条件**: メイン機の CLI + dotfiles が home-manager 管理下に入り、
brew は GUI / cask と nixpkgs 未収録パッケージ専用になる。

### Phase 3-3: WSL2 — `[?]` 条件付き（実稼働待ち）

**着手トリガー**: 会社の業務プロジェクトが動き始め、WSL2 を日常的に使うようになったとき。

詳細な作業計画・設計: [PHASE-3-3-WSL2.md](PHASE-3-3-WSL2.md)

- `targets.genericLinux.enable = true` が必要
- flake の出力が `homeConfigurations` 系統になる（nix-darwin とは独立）
- `git gtr` は Homebrew 専用 tap のため Linux 対応を要確認

**完了条件**: WSL2 上で `home-manager switch` により zsh / starship / git が再現できる。

---

## Phase 4: 付加機能の順次導入 — `[ ]`

> Phase 3 の完了を待たず、**タイミングが来たものから個別に導入する**。
> 一気に進めない。各項目は独立している。
>
> （旧 Phase 4「nix-darwin 移行」は Phase 3 に吸収した）

### 4-1: Remote builders — `[ ]` 優先度: 高

hermes をビルドマシンにし、MacBook Pro のビルド負荷を逃がす。
両機とも `aarch64-darwin` なので成果物がそのまま使える。

**stow では原理的に代替不可能な唯一の価値。** ヘッドレス機の存在価値が上がる。

- [ ] hermes を builder として登録（`nix.buildMachines`）
- [ ] `builders-use-substitutes` を有効化してキャッシュ併用
- [ ] MacBook Pro でのビルドが hermes に委譲されることを確認

**完了条件**: MacBook Pro で `darwin-rebuild` を実行したとき、重いビルドが hermes で走る。

**前提**: Phase 3-1 完了

### 4-2: `comma`（`,` コマンド）— `[ ]` 優先度: 高

インストールせずコマンドを即実行する。導入コストがほぼゼロ。

- [ ] `comma` と `nix-index` を導入
- [ ] `nix-index` データベースの定期更新を設定

**完了条件**: `, <command>` で未インストールのコマンドが実行できる。

### 4-3: `nix flake check` + CI — `[ ]` 優先度: 中

設定自体の検証。リポジトリに `.github` が無く **CI 未設定のため純増**。
`link-tmux` の腐敗は CI があれば検出できていた。

- [ ] `nix flake check` が通る状態にする
- [ ] treefmt-nix でフォーマッタを統合（mozumasu 採用）
- [ ] GitHub Actions で `nix flake check` を実行

**完了条件**: push 時に設定の破綻が自動検出される。

### 4-4: Cachix Deploy — `[ ]` 優先度: 中

hermes が pull 型で設定に自動追従する。
現状は SSH して `install-hermes-subset.sh` を叩きに行く必要がある。

**注意**: 外部サービス依存。まず手動運用に慣れてから。

**前提**: Phase 3-1 完了

### 4-5: sops-nix — `[ ]` 優先度: 中

秘匿情報を暗号化したままコミットする。
現状は `shared/cliproxyapi.conf.tmpl` のテンプレート化と
`~/.claude-work`（git 管理外）で回避しており、**秘匿情報だけリポジトリの外**にある。

**着手トリガー**: 3 台目が実稼働し、各マシンへの手動配置が負担になったとき。

### 4-6: `specialisation` — `[ ]` 優先度: 低

同一ホストで設定バリアントを切り替える。
`ccw` / `taktw`（会社アカウント切替、`~/.claude-work`）の宣言化に使える。

**注意**: home-manager 版は**実験的機能**。採用するなら nix-darwin 側で。
現状の zsh 関数で動いているため急がない。

### 4-7: Tier 2 機能（採否未判断）— `[ ]`

| 機能 | 内容 |
|---|---|
| overlays | nixpkgs のパッケージを部分上書き・patch。upstream が壊れていても自分で直せる |
| 自作パッケージ（`packages/`） | nixpkgs 未収録の CLI を宣言に載せる。`agent-browser` / `git-gtr` / `takt` が候補 |
| `dockerTools` | Dockerfile なしで OCI イメージ生成。レイヤ最適化が自動 |
| flake templates | `nix flake init -t` でプロジェクト雛形 |
| `nh`（nix helper） | rebuild の UX 改善・差分表示（ryoppippi 採用） |

---

## Phase 5: 対象外と判断したもの（記録）— `[-]`

再検討時に「なぜ採らなかったか」を追えるように残す。

| 項目 | 理由 |
|---|---|
| NixOS 本体 / impermanence / microVM | Linux サーバを常用しないため無関係 |
| deploy-rs / colmena / NixOps | 複数サーバへのデプロイ用。対象がない |
| devenv.sh / Devbox | mise と重複。Nix 本体を学ぶ方針のため迂回不要 |
| lazy2nix 相当（nvim プラグインの Nix 化） | `lazy-lock.json` で既にピン留めしており追加価値が小さい |
| zsh の zcompile / init キャッシュ / zsh-defer | 実測 0.244 秒で既に十分速い |

---

## 既存ツールとの共存方針

| ツール | 方針 |
|---|---|
| **stow** | 段階的に home-manager へ寄せ、**最終的に廃止**（Phase 3-2 完了後） |
| **mise** | **残す**。境界は「言語ランタイム = mise、それ以外の CLI = Nix」 |
| **brew** | GUI / cask と nixpkgs 未収録パッケージ用に**恒久的に残る**。`homebrew.*` で宣言化 |

**brew が恒久的に残る理由**: `agent-browser` / `git-gtr`（サードパーティ tap）/
`gemini-cli` / `opencode` / `claude-code` / `codex` は nixpkgs 未収録または追従が遅い。
**日常的に使う AI CLI 群こそ brew に残る**（Phase 4-7 の自作パッケージ化で一部は移せる可能性がある）。

---

## 進行ルール

- Phase は原則 **順番に**進める。ただし **前提が変わった場合は ROADMAP ごと見直す**
  - 2026-07-29: 3 台構成が判明し Phase 1 のスキップを決定
  - 2026-07-30: WSL2 の稼働実態が判明し着手順序を反転、nix-darwin を前倒し
- **Phase 4 は Phase 3 の完了を待たない。** 各項目は独立しており、タイミングが来たものから導入する
- 各 Phase の中で「採用 / 不採用 / 保留」の判断が出たら **ADR を書く**
- 学習が追いつかない場合は、その Phase に**無期限で滞留してよい**
- **実装は mozumasu の構造をコピーして削る。** ゼロから設計しない
- ROADMAP は学習状況に応じて随時更新（固定計画ではない）
