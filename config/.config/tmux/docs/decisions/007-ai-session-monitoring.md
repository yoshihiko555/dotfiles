# ADR-007: AI セッション監視ツールの選定

- **状態**: 承認・実施済み (試用中)
- **日付**: 2026-03-17

## コンテキスト

複数プロジェクトで Claude Code, Codex, Gemini 等を並列実行する運用において、セッション横断で各エージェントの状態 (working/idle/waiting) を把握し、承認待ちのインスタンスに即ジャンプしたいという要件があった。

## 選択肢

| ツール | 既存ペイン検知 | セッション占有 | detach キー | 評価 |
|--------|--------------|--------------|------------|------|
| claude-squad | 独自セッションのみ | する (セッション=エージェント専用) | `Ctrl+Q` (固定、変更不可) | 運用フローと重複が大きい |
| claude-tmux | 既存 tmux ペインの `claude` を検知 | しない | 不要 (独自 TUI) | 既存フローと共存可能 |
| 自作 ai-orchestra スクリプト | ai-orchestra セッションのみ | しない | - | 対象が限定的 |

### claude-squad の問題点

1. セッション管理が sessionizer と重複 (二重管理)
2. セッション内が Claude Code 専用になり、Neovim + Claude のレイアウトが不可
3. detach キー `Ctrl+Q` が WezTerm Leader と衝突し、popup 内で完全にスタックする
4. display-popup でのアタッチ後に抜ける手段がない

### claude-tmux の利点

1. 既存の tmux ペインで動いている `claude` プロセスを自動検知
2. セッションを乗っ取らない。自由なレイアウト (Neovim + Claude + shell) を維持
3. `Ctrl+Q` 問題なし
4. sessionizer ベースの運用フローとそのまま共存

## 決定

**claude-tmux** を AI セッション監視ツールとして採用 (試用)。`Prefix+b` で popup 起動。

claude-squad は Ctrl+Q 衝突問題と運用フロー重複のため保留。セッション・worktree のクリーンアップ後にアンインストール予定。

## 影響

- `Prefix+b` で claude-tmux のダッシュボードを popup 起動
- cargo (Rust) が新たな依存に追加。mise で管理
- 一部セッションで Claude Code のステータスが `unknown` になる検知精度の課題あり (試用中に確認)
- claude-squad のアンインストールは別途実施 (worktree ゴミデータの確認が必要)
