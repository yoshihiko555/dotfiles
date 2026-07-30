# Nix 設定

dotfiles 配下の Nix 管理エントリポイント。
stow 経由で `~/.config/nix/` にリンクされる。

## 現状 (Phase 0 完了 / 次は Phase 3-0 → 3-1 hermes)

- Nix 2.34.5 インストール済み
- `flake.nix` は最小の devShell 定義のみ（`git` / `jq` / `ripgrep`）
- `nix profile` での常用ツール管理は行わない（Phase 1 はスキップ）
- `shell/.zprofile` で login shell でも Nix を初期化

**nix-darwin + home-manager** で 3 台を宣言的に管理する方針。

| ホスト | system | Nix の適用範囲 | 着手順 |
|---|---|---|---|
| Mac mini (hermes, M4) | `aarch64-darwin` | ほぼ全体。**cask は乗せない**（ヘッドレス） | **1（次）** |
| MacBook Pro | `aarch64-darwin` | CLI + dotfiles（GUI / cask は brew のまま） | 2 |
| 会社 Windows (WSL2) | `x86_64-linux` | WSL2 内部のみ（Windows 本体は対象外） | 3（実稼働待ち） |

### 目的

1. **環境依存の切り分けを宣言的に表現する**（ヘッドレス機に GUI cask を乗せない等）
2. **新端末で環境を引き継げるようにする**（現状 8 手順 → 1 コマンド）
3. 複数マシンで同一環境を構築する

目的から外したもの: スキル管理の宣言化 / devShell + direnv（mise と重複）/
zsh 起動最適化（実測 0.244 秒で十分）/ launchd の宣言管理。

詳細な移行計画・意思決定の履歴:

- [docs/ROADMAP.md](docs/ROADMAP.md) — 段階的な移行計画（**完了状態つき**）
- [docs/PHASE-3-3-WSL2.md](docs/PHASE-3-3-WSL2.md) — WSL2 の作業計画・設計（実稼働待ち）
- [docs/adr/DECISIONS.md](docs/adr/DECISIONS.md) — ADR 一覧

## 常用コマンド

```sh
# 最小の devShell に入る
nix develop ~/.config/nix

# flake の入力を更新
nix flake update --flake ~/.config/nix

# インストール済みツール一覧
nix profile list
```

## トラブルシュート

- `nix` コマンドが見つからない: login shell で `shell/.zprofile` の Nix 初期化が走っているか確認
- flake 関連エラー: `~/.config/nix/nix.conf` に `experimental-features = nix-command flakes` が入っているか確認
