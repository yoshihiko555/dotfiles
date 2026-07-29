# Nix 設定

dotfiles 配下の Nix 管理エントリポイント。
stow 経由で `~/.config/nix/` にリンクされる。

## 現状 (Phase 0 完了 / 次は Phase 3-1)

- Nix 2.34.5 インストール済み
- `flake.nix` は最小の devShell 定義のみ（`git` / `jq` / `ripgrep`）
- `nix profile` での常用ツール管理は行わない（Phase 1 はスキップ）
- `shell/.zprofile` で login shell でも Nix を初期化

3 台（MacBook Pro / Mac mini(hermes) / 会社 Windows の WSL2）を home-manager で
宣言的に管理する方針。次の着手は WSL2（Phase 3-1）。

| ホスト | system | Nix の適用範囲 |
|---|---|---|
| MacBook Pro | `aarch64-darwin` | CLI + dotfiles（GUI / cask は brew のまま） |
| Mac mini (hermes, M4) | `aarch64-darwin` | ほぼ全体 |
| 会社 Windows (WSL2) | `x86_64-linux` | WSL2 内部のみ（Windows 本体は対象外） |

詳細な移行計画・意思決定の履歴:

- [docs/ROADMAP.md](docs/ROADMAP.md) — 段階的な移行計画
- [docs/PHASE-3-1-WSL2.md](docs/PHASE-3-1-WSL2.md) — 次の着手対象（WSL2）の作業計画・設計
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
