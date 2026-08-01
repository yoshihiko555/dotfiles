# Nix 設定

dotfiles 配下の Nix 管理エントリポイント。
stow 経由で `~/.config/nix/` にリンクされる。

## 現状 (Phase 3-1 完了 / 次は Phase 3-2 → MacBook Pro)

- hermes（Mac mini）は `darwin-rebuild switch --flake .#hermes` により
  nix-darwin + home-manager 管理下に入った（2026-07-31）
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
zsh 起動最適化（実測 0.244 秒で十分）/ launchd の宣言管理。

詳細な移行計画・意思決定の履歴:

- [docs/GUIDE.md](docs/GUIDE.md) — **設定ファイルの読み方ガイド（学習用）**。どのファイルが何をしていて、nix-darwin / home-manager とどう繋がるか
- [docs/CHEATSHEET.md](docs/CHEATSHEET.md) — **日常運用チートシート**。反映・rollback・パッケージ追加・更新・掃除の実用コマンド集
- [docs/ROADMAP.md](docs/ROADMAP.md) — 段階的な移行計画（**完了状態つき**）
- [docs/PHASE-3-3-WSL2.md](docs/PHASE-3-3-WSL2.md) — WSL2 の作業計画・設計（実稼働待ち）
- [docs/adr/DECISIONS.md](docs/adr/DECISIONS.md) — ADR 一覧

## セットアップ（新しい Mac）

初回 bootstrap の手順。hermes（2026-07-31）で実施・検証済み。

1. **Determinate pkg 版で Nix をインストール**する
   （シェル版は macOS 26 (Tahoe) で `/etc/fstab` 書き込みに失敗する）。
   `https://install.determinate.systems/determinate-pkg/stable/Universal` を
   `installer -pkg` で導入する
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
- flake 関連エラー: `~/.config/nix/nix.conf` に `experimental-features = nix-command flakes` が入っているか確認
