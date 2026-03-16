# ADR-002: Stow パスを XDG 準拠に変更

- **状態**: 承認・実施済み
- **日付**: 2026-03-16

## コンテキスト

現在の tmux 設定は以下のパスに配置:

```
tmux/.tmux.conf          → ~/.tmux.conf       (旧)
tmux/.tmux/bin/           → ~/.tmux/bin/       (旧)
```

tmux 3.1+ は `~/.config/tmux/tmux.conf` を自動検索する (XDG Base Directory 対応)。

## 決定

Phase 1 で Stow パスを XDG 準拠に変更し、config stow パッケージに統合した。

```
config/.config/tmux/tmux.conf     → ~/.config/tmux/tmux.conf
config/.config/tmux/conf/         → ~/.config/tmux/conf/
config/.config/tmux/bin/          → ~/.config/tmux/bin/
config/.config/tmux/docs/         → ~/.config/tmux/docs/
```

### 理由

1. XDG Base Directory 仕様に準拠 (他の dotfiles と統一)
2. `~` 直下のドットファイル汚染を削減
3. `conf/` でモジュール分割しやすい構造

## 影響

- 全スクリプトの `~/.tmux/bin/` パスを `~/.config/tmux/bin/` に変更済み
- conf ファイル内のパスも `~/.config/tmux/bin/` に更新済み
- tmux 3.1 未満では動作しない (現環境は 3.6 なので問題なし)
- stow パッケージが `tmux` → `config` に変更。`stow-worktree.sh` 実行時は `config` を指定
