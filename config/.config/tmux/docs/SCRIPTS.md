# ヘルパースクリプト

`bin/` 配下のスクリプト一覧。全て `~/.config/tmux/bin/` にインストールされる。

## 概要

| スクリプト | 分類 | 概要 |
|-----------|------|------|
| tmux-session-tabs | UI | ステータスバー用セッションタブ表示 |
| tmux-switch-session | ナビ | N 番目のセッションに切替 |
| tmux-toggle-claude | 制御 | Claude 監視ペインのトグル |
| tmux-watch-claude-panes | 監視 | ai-orchestra ペイン一覧ダッシュボード |
| tmux-follow-claude-pane | 監視 | 単一ペインのリアルタイム追跡 |
| tmux-select-claude-session | 選択 | ai-orchestra セッション選択 (fzf) |
| tmux-select-claude-pane | 選択 | ai-orchestra ペイン選択 (fzf) |
| tmux-list-orchestra-sessions | 問合 | アクティブな ai-orchestra セッション一覧 |
| tmux-pane-claude | 入口 | 監視をペイン内で起動 |
| tmux-popup-claude | 入口 | 監視をポップアップで起動 |
| tmux-popup-claude-history | 閲覧 | サブエージェント履歴閲覧 |
| tmux-save-pane-snapshot | 保存 | ペイン内容のスナップショット保存 |
| tmux-open-pane-snapshot | 閲覧 | スナップショットを less で表示 |

---

## セッション/UI 系

### tmux-session-tabs

ステータスバー左側にセッション一覧をタブ形式で表示する。

- `claude-*` セッションは非表示
- 現在のセッションはシアン (`#3BC1A8`) でハイライト
- Powerline Extra グリフ使用

**使用箇所**: `status-left` の `#(~/.config/tmux/bin/tmux-session-tabs)`

### tmux-switch-session

`tmux-switch-session <N>` で N 番目の非 Claude セッションに切替。

- `claude-*` セッションを除外してアルファベット順にソート
- Alt+1-9 キーバインドから呼ばれる

---

## ai-orchestra 監視系

ai-orchestra のサブエージェント (Claude, Codex, Gemini 等) を tmux 上でリアルタイム監視するスクリプト群。

### 呼出フロー

```
Prefix+A (トグル)
  └→ tmux-toggle-claude
       └→ tmux-pane-claude
            ├→ tmux-select-claude-session (fzf)
            └→ tmux-watch-claude-panes (ダッシュボード)

Prefix+a (履歴)
  └→ tmux-popup-claude-history
       ├→ tmux-select-claude-session (fzf)
       ├→ tmux-select-claude-pane (fzf + プレビュー)
       └→ tmux-follow-claude-pane (リアルタイム追跡)
```

### tmux-watch-claude-panes `<session>`

全ペインをグリッド表示するダッシュボード。

- 1 秒間隔で更新、差分検出で不要な再描画を回避
- ペイン状態: `RUNNING` (シアン), `DONE` (緑) で色分け
- ターミナルリサイズに追従

### tmux-follow-claude-pane `<session> <pane_id> [status] [title]`

単一ペインの出力をリアルタイム追跡。

- `Ctrl+C` で一時停止、`F` で再開、`q` で終了
- ペインリセット検出で自動終了
- `less` で全履歴を閲覧可能

### tmux-select-claude-session

アクティブな ai-orchestra セッションを fzf で選択。単一セッションの場合は自動選択。

### tmux-select-claude-pane `<session>`

セッション内のペインを fzf で選択。プレビューに末尾 120 行を表示。

### tmux-list-orchestra-sessions

`$CLAUDE_TMUX_SESSION_INFO_DIR` からアクティブセッション一覧を取得。存在確認 + 重複排除済み。

### tmux-toggle-claude

Claude 監視ペイン (右 40%) の表示/非表示をトグル。`claude-watch` タイトルで識別。

---

## スナップショット系

### tmux-save-pane-snapshot `[pane-id]`

ペインズーム時 (`Prefix+z`) に自動呼出。ペイン内容を `~/.cache/tmux/pane-snapshots/` に保存。

- 代替画面 + ヒストリバッファの両方をキャプチャ
- メタデータ (セッション名, コマンド, プロジェクト等) を記録
- アトミック書込み

### tmux-open-pane-snapshot `[pane-id]`

保存済みスナップショットを `less -R` で表示 (`Prefix+V` で呼出)。

---

## 未実装 (移行計画で追加予定)

| スクリプト | 概要 | Phase |
|-----------|------|-------|
| tmux-sessionizer | GHQ プロジェクト picker (fzf, repo/worktree アイコン付き) | 2 |
| tmux-kill-session | セッション削除 (fzf) | 2 |
| tmux-init-panes | ペイン数に応じて AI ツール自動起動 | 4 |
| tmux-baton-status | baton ステータス取得 | 4 |
| tmux-command-menu | コマンドパレット (fzf) | 5 |
| tmux-url-handler | URL 選択 → 開く | 5 |

### tmux-sessionizer (Phase 2)

WezTerm の `select_project` 相当。GHQ リポジトリ + git worktree を fzf で選択し、tmux セッションを作成/切替する。

**UI 仕様** (WezTerm の視覚デザインを踏襲):

```
  ○ 🖥 default
  ○ 🖥 digital-garden
  ● 🔀 dotfiles:tmux   (current)
  ○ 🖥 learno
  ○ 🖥 tech-site
```

- `repo-list.sh` の TYPE でアイコンを分岐: `repo` → `○ 🖥`, `worktree` → `● 🔀`
- 現在のセッションに `(current)` マーカー付与
- セッション名規則: worktree は `repo:branch`, repo は末尾ディレクトリ名
- データソース: `scripts/repo-list.sh` (WezTerm と共有)
- キーバインド: `Prefix + f` → `display-popup -E -w 80% -h 70%`

### tmux-kill-session (Phase 2)

fzf でセッション選択 → 削除。現在のセッションと `claude-*` は除外。

- キーバインド: `Prefix + W` → `display-popup -E -w 60% -h 50%`
