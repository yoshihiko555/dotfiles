# Nix 設定

dotfiles 配下の Nix 管理エントリポイント。
stow 経由で `~/.config/nix/` にリンクされる。

## 現状 (Phase 0)

- Nix 2.34.5 インストール済み
- `flake.nix` は最小の devShell 定義のみ（`git` / `jq` / `ripgrep`）
- `nix profile` での常用ツール管理はまだ開始していない
- `shell/.zprofile` で login shell でも Nix を初期化

詳細な移行計画・意思決定の履歴:

- [docs/ROADMAP.md](docs/ROADMAP.md) — 段階的な移行計画
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
