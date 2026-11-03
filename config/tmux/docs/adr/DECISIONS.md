# 意思決定ログ (DECISIONS)

tmux 関連の意思決定の一覧。詳細は各 ADR ファイルを参照。
領域をまたぐ決定は [docs/adr/](../../../../docs/adr/DECISIONS.md) に置く。

| ID | タイトル | ステータス | 決定日 | 主な理由 | タグ |
|---|---|---|---|---|---|
| [ADR-20260316-0001](ADR-20260316-0001-tmux-first-architecture.md) | tmux-first アーキテクチャの採用 | 採用 | 2026-03-16 | ポータビリティ / エコシステム / シンプル | Architecture |
| [ADR-20260316-0002](ADR-20260316-0002-stow-path-migration.md) | Stow パスを XDG 準拠に変更 | 採用 | 2026-03-16 | XDG 準拠 / ホーム直下の汚染削減 / モジュール分割 | Structure |
| [ADR-20260316-0003](ADR-20260316-0003-baton-vs-claude-squad.md) | baton vs claude-squad の選定 | 提案 | 2026-03-16 | ワークフロー統合度 / tmux-monitor との共存 / 操作の快適さ | Agent |
| [ADR-20260317-0004](ADR-20260317-0004-prefix-key-change.md) | Prefix キーの変更 (Ctrl+B → Ctrl+T → Ctrl+Q) | 採用 | 2026-03-17 | WezTerm Leader との衝突回避 | Keybind |
| [ADR-20260317-0005](ADR-20260317-0005-statusbar-design.md) | ステータスバーを WezTerm デザインに準拠 | 採用 | 2026-03-17 | 移行前後の操作体験の一貫性 | UI |
| [ADR-20260317-0006](ADR-20260317-0006-tpm-plugin-selection.md) | TPM 導入と Phase 3 プラグイン選定 | 採用 | 2026-03-17 | QuickSelect 相当の補完 / 別端末での自動セットアップ | Plugin |
| [ADR-20260317-0007](ADR-20260317-0007-ai-session-monitoring.md) | AI セッション監視ツールの選定 | 廃止 | 2026-03-17 | 既存ペインとの共存 / セッションを占有しない | Agent |
| [ADR-20260317-0008](ADR-20260317-0008-wezterm-reduction.md) | WezTerm 設定の縮小 (Phase 6) | 採用 | 2026-03-17 | 管理を tmux に統一 / WezTerm は GUI レンダラーに限定 | Terminal |
| [ADR-20260317-0009](ADR-20260317-0009-smart-splits-nvim.md) | smart-splits.nvim 導入 (Neovim ↔ tmux シームレス移動) | 採用 | 2026-03-17 | WezTerm 側の移動処理の削除で戻れなくなった | Keybind/Neovim |
