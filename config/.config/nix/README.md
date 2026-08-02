# Nix 設定

dotfiles 配下の Nix 管理エントリポイント。
stow 経由で `~/.config/nix/` にリンクされる。

## 現状 (Phase 3-1 / 3-1b / 3-1c 完了 / 次は Phase 3-2 → MacBook Pro)

- hermes（Mac mini）は nix-darwin + home-manager 管理下（2026-07-31）。
  CLI・LLM 基盤・launchd デーモンまで宣言管理済みで、brew 残留は cask + git-gtr のみ（3-1b、2026-08-01）
- hermes は 2026-08-02 に Determinate Nix から素の Nix（`NixOS/nix-installer`）へ移行し、
  MacBook Pro と Nix 本体の系統が揃った（3-1c。経緯・検証は
  [ADR-0005](docs/adr/ADR-20260802-0005-upstream-nix-migration.md) 参照）
- MacBook Pro / 会社 Windows (WSL2) は未着手。`flake.nix` の最小 devShell 定義
  （`git` / `jq` / `ripgrep`）のみが適用されている
- `nix profile` での常用ツール管理は行わない（Phase 1 はスキップ）
- `shell/.zprofile` で login shell でも Nix を初期化

**nix-darwin + home-manager** で 3 台を宣言的に管理する方針。

| ホスト | system | Nix の適用範囲 | 着手順 |
|---|---|---|---|
| Mac mini (hermes, M4) | `aarch64-darwin` | ほぼ全体。cask は**宣言管理（7 個）** | **1（完了、2026-07-31）** |
| MacBook Pro | `aarch64-darwin` | CLI + dotfiles（GUI / cask は brew のまま） | **2（次）** |
| 会社 Windows (WSL2) | `x86_64-linux` | WSL2 内部のみ（Windows 本体は対象外） | 3（実稼働待ち） |

### 目的

1. **環境依存の切り分けを宣言的に表現する**（ヘッドレス機に GUI cask を乗せない等）
2. **新端末で環境を引き継げるようにする**（現状 8 手順 → 1 コマンド）
3. 複数マシンで同一環境を構築する

目的から外したもの: スキル管理の宣言化 / devShell + direnv（mise と重複）/
zsh 起動最適化（実測 0.244 秒で十分）/ launchd の宣言管理（**hermes のみ例外**でスコープ入り、ROADMAP 参照）。

詳細な移行計画・意思決定の履歴:

- [docs/GUIDE.md](docs/GUIDE.md) — **設定ファイルの読み方ガイド（学習用）**。どのファイルが何をしていて、nix-darwin / home-manager とどう繋がるか
- [docs/CHEATSHEET.md](docs/CHEATSHEET.md) — **日常運用チートシート**。反映・rollback・パッケージ追加・更新・掃除の実用コマンド集
- [docs/USECASES.md](docs/USECASES.md) — **ユースケースカタログ**。次に何をやるかの判断材料（価値・コスト・向き不向き）
- [docs/ROADMAP.md](docs/ROADMAP.md) — 段階的な移行計画（**完了状態つき**）
- [docs/PHASE-3-3-WSL2.md](docs/PHASE-3-3-WSL2.md) — WSL2 の作業計画・設計（実稼働待ち）
- [docs/adr/DECISIONS.md](docs/adr/DECISIONS.md) — ADR 一覧

## 運用規約（正式決定事項の一覧）

決定の経緯・理由は各 ADR を参照。ここは「守るルールの一覧」に徹する。

### 構成（[ADR-0004](docs/adr/ADR-20260801-0004-module-layer-design.md)）

- **3 層構成**: `darwin/` = darwin 共通システム層 / `home/` = 全台共通ユーザー層 /
  `hosts/<host>/` = ホスト固有（**薄く保つ**）。WSL2 は darwin 層を通らない
- `hosts/<host>/` は「hostSpec + 目次の default.nix + 機能群ファイル」。
  機能の増築は**新ファイル + imports に 1 行**
- **2 台以上で使い始めたら共通層へ昇格**。新規はまず使うホストの hosts/ に書く

### 方式（[ADR-0003](docs/adr/ADR-20260730-0003-purpose-and-order.md)）

- 原則 **`mkOutOfStoreSymlink`**（編集即反映）。例外は `home.activation` とし、
  **理由コメント必須**
- 設定内容を Nix 言語へ書き直す全面移行（`programs.*`）はしない

### パッケージの置き場

| 種別 | 置き場 |
|---|---|
| nixpkgs 収録の CLI（全台共通） | `home/packages.nix` |
| nixpkgs 未収録の formula | `darwin/homebrew.nix`（共通）/ `hosts/<host>/homebrew.nix`（固有） |
| cask（GUI） | `hosts/<host>/homebrew.nix` |
| 言語ランタイム | mise（Nix では管理しない） |

### 運用

- **brew で直接入れたら必ず宣言にも追加**する（宣言外は次の switch で zap が削除）
- **1 switch = 1 変更クラス**。検証はカテゴリを混ぜず、rollback 可能な単位で
- 反映フロー: 編集 → push → 対象ホストで pull。設定ファイルの中身だけなら pull で完了、
  パッケージ・配線の変更は + switch
- 方針の再議論は「**前提が変わったとき」だけ**。採用/不採用の判断が出たら ADR を書く
- hermes への SSH は `macmini-agent`、管理作業のみ `macmini-admin`（ルート AGENTS.md 参照）

## セットアップ（新しい Mac）

初回 bootstrap の手順。hermes で実施・検証済み（nix-darwin 導入は 2026-07-31、
素の Nix 系統への移行検証は 2026-08-02。経緯は
[ADR-0005](docs/adr/ADR-20260802-0005-upstream-nix-migration.md) 参照）。

1. **[`NixOS/nix-installer`](https://github.com/NixOS/nix-installer)（素の Nix）で
   Nix をインストール**する（`--enable-flakes` 付き）。hermes では 2.35.1 を
   Tahoe 26.4.1 で導入し動作を確認済み（**要確認**: 実行したコマンド行の記録が
   残っていないため、GitHub のリリースページの手順に従う）。
   Determinate 系は使わない（[ADR-0005](docs/adr/ADR-20260802-0005-upstream-nix-migration.md)）。
   Tahoe で `/etc/fstab` 書き込みに失敗するのは **Determinate 版インストーラ固有**の問題で、
   `NixOS/nix-installer` では発生しない
2. dotfiles を ghq で clone する
3. （repo 所有者と sudo 実行者が異なる場合のみ）root へ
   `git config --global --add safe.directory <repo>` を登録する
4. `/etc/zshenv` `/etc/zshrc` `/etc/zprofile` を `*.before-nix-darwin` へ退避する
5. 初回 switch を実行する

   ```sh
   sudo -H /nix/var/nix/profiles/default/bin/nix run github:nix-darwin/nix-darwin/master#darwin-rebuild -- \
     switch --flake <repo>/config/.config/nix#<host>
   ```

   2 回目以降は `darwin-rebuild` が `/run/current-system/sw/bin` に入るため、以下で足りる。

   ```sh
   sudo darwin-rebuild switch --flake <repo>/config/.config/nix#<host>
   ```

> **SSH 越しに行う場合**: 「システム設定 → 共有 → リモートログイン →
> リモートユーザーにフルディスクアクセスを許可」を ON にしておく必要がある
> （OFF だと root でも `/etc/fstab` 等の rename が `Operation not permitted` になる）。

## 常用コマンド

```sh
# 最小の devShell に入る
nix develop ~/.config/nix

# flake の入力を更新
nix flake update --flake ~/.config/nix

# インストール済みツール一覧
nix profile list

# hermes の設定を再適用（hermes 上で実行。$DOTFILES は /etc/zshenv 経由で全ユーザーに設定済み。
# sudo の前にシェルが展開するのでそのまま通る）
sudo darwin-rebuild switch --flake "$DOTFILES/config/.config/nix#hermes"
```

## トラブルシュート

- `nix` コマンドが見つからない: login shell で `shell/.zprofile` の Nix 初期化が走っているか確認
- flake 関連エラー: `~/.config/nix/nix.conf`（stow でリンクされるユーザーレベル設定。
  ブートストラップ時や WSL2 など darwin 層を通らないホストで参照される）に
  `experimental-features = nix-command flakes` が入っているか確認。
  nix-darwin 管理下の Mac（hermes 等）ではシステム側の `/etc/nix/nix.conf` は
  `darwin/default.nix` の `nix.settings` が管理するため、両者は別物として扱う
