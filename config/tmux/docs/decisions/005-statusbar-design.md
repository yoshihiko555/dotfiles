# ADR-005: ステータスバーを WezTerm デザインに準拠

- **状態**: 承認・実施済み
- **日付**: 2026-03-17

## コンテキスト

Phase 1 の設定分割後、ステータスバーのデザインを再設計する必要があった。WezTerm から tmux への移行において、操作体験の一貫性を保つために WezTerm のステータスバー構成に合わせることにした。

## 決定

WezTerm の 3 領域構成を tmux ステータスバーに移植した。

### レイアウト

| 領域 | WezTerm | tmux |
|------|---------|------|
| 左 | モードバッジ (LEADER/COPY/PANE/SEARCH) | モードバッジ (PREFIX/COPY/PANE/RESIZE) |
| 中央 | タブバー (プロセス名、Powerline Extra グリフ) | window-status (プロセス名、Powerline Extra グリフ) |
| 右 | ワークスペース名 (repo/worktree アイコン) + 日時 | セッション名 (repo/worktree アイコン) + 日時 |

### 実装方針

- **ウィンドウ一覧**: tmux ネイティブの `window-status-format` を使用し即時更新。Powerline Extra グリフは `run-shell` 経由で `tmux-apply-statusbar` スクリプトから設定
- **右側**: `tmux-status-right` スクリプトで描画。セッション名の `:` 有無で repo/worktree アイコンを切替
- **ウィンドウ名**: `automatic-rename-format` を `#{pane_current_command}` に変更し、プロセス名を表示

### カラーパレット (Tokyo Night Moon)

| 要素 | 色 |
|------|-----|
| アクティブタブ bg | `#3BC1A8` |
| 非アクティブタブ bg | `#005461` |
| セッション名 bg | `#394270` |
| 日時 bg | `#82aaff` |

## 影響

- ステータスバーの右側は外部スクリプト (`#()`) で 1 秒間隔更新のため、セッション切替時に表示ラグがある
- ウィンドウ一覧はネイティブ描画で即時更新
- Powerline グリフは conf ファイルに直接埋め込めないため、`tmux-apply-statusbar` スクリプトが必要
