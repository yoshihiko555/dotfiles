# ヘルパースクリプト

`bin/` 配下のスクリプト一覧。全て `~/.config/tmux/bin/` にインストールされる。

## 現在の使用状況

| スクリプト | 状態 | 使用箇所 | 概要 |
|-----------|------|----------|------|
| tmux-apply-statusbar | 現役 | `statusbar.conf` | Powerline 付き `window-status-format` を適用 |
| tmux-status-right | 現役 | `statusbar.conf` | セッション名 + 日時を右側に描画 |
| tmux-save-pane-snapshot | 現役 | `keybinds.conf`, `pane-mode.conf` | ペイン内容のスナップショット保存 |
| tmux-open-pane-snapshot | 現役 | `copy-mode.conf` | 保存済みスナップショットを popup で表示 |
| tmux-list-claude-panes | 現役 | Claude pane ダッシュボード内部 | Claude Code pane をペイン単位で一覧化 |
| tmux-popup-claude-dashboard | 現役 | `popup.conf` (`Prefix+b`) | Claude Code pane の横断選択 UI |
| tmux-open-claude-target | 現役 | `popup.conf` (`Prefix+b`) | popup 終了後に親クライアントで対象 pane へ移動 |
| tmux-toggle-claude | 現役 | `popup.conf` (`Prefix+A`) | AI 監視ペインをトグル |
| tmux-pane-claude | 現役 | `tmux-toggle-claude` | 監視ペイン内の入口 |
| tmux-popup-claude-history | 現役 | `popup.conf` (`Prefix+a`) | AI 履歴の選択と閲覧 |
| tmux-list-orchestra-sessions | 現役 | AI 監視フロー内部 | ai-orchestra セッション一覧を取得 |
| tmux-select-claude-session | 現役 | AI 監視フロー内部 | セッション選択 (fzf) |
| tmux-select-claude-pane | 現役 | AI 履歴フロー内部 | ペイン選択 (fzf + preview) |
| tmux-watch-claude-panes | 現役 | AI 監視フロー内部 | セッション全体をリアルタイム監視 |
| tmux-follow-claude-pane | 現役 | AI 履歴フロー内部 | 単一ペインを `less +F` で追跡 |
| tmux-popup-claude | 補助 | 手動実行用 | 監視ダッシュボードを popup で起動 |
| tmux-switch-session | 補助 | 手動実行用 | N 番目の非 Claude セッションへ切替 |
| tmux-status-left | 未接続 | - | モードバッジのスクリプト版。現行設定では inline format を採用 |
| tmux-session-tabs | 未接続 | - | 旧セッションタブ表示ヘルパー |
| tmux-window-status | 未接続 | - | 旧ウィンドウタブ描画ヘルパー |
| tmux-session-icon | 未接続 | - | セッション名から repo/worktree アイコンを返す小ユーティリティ |

---

## ステータスバー系

### 現行構成

- 左: `status-left` に inline でモードバッジを定義
- 中央: tmux ネイティブのウィンドウ一覧
- 右: `tmux-status-right`
- Powerline の左右三角は `tmux-apply-statusbar` が `window-status-format` を上書きして適用

### tmux-apply-statusbar

`window-status-format` / `window-status-current-format` を Powerline 風に整形する。

- 非アクティブ: `#005461`
- アクティブ: `#3BC1A8`
- 現在のウィンドウ名文字色は非アクティブと同じ `#c8d3f5`

### tmux-status-right

右側にセッション名と日時を描画する。

- セッション名に `:` を含む場合は worktree アイコン
- それ以外は repo アイコン
- 日時は `MM/DD HH:MM` 形式

### 未接続の旧 UI ヘルパー

- `tmux-session-tabs`: 旧 `status-left` 用。現在は使っていない
- `tmux-window-status`: 旧ウィンドウ一覧用。現在は使っていない
- `tmux-status-left`: モードバッジのスクリプト版。現在は shell 呼び出しを避けるため inline 化
- `tmux-session-icon`: 単機能ユーティリティ。現行の右側表示は `tmux-status-right` 内で完結

---

## ai-orchestra 監視系

ai-orchestra のサブエージェント (Claude, Codex, Gemini 等) を tmux 上で監視するスクリプト群。

### 呼出フロー

```
Prefix+A (トグル)
  └→ tmux-toggle-claude
       └→ tmux-pane-claude
            ├→ tmux-select-claude-session (fzf)
            └→ tmux-watch-claude-panes

Prefix+a (履歴)
  └→ tmux-popup-claude-history
       ├→ tmux-select-claude-session (fzf)
       ├→ tmux-select-claude-pane (fzf + preview)
       └→ tmux-follow-claude-pane
```

### tmux-watch-claude-panes `<session>`

セッション内の全ペインを縦積みでリアルタイム表示する。

- 1 秒間隔で更新
- `RUNNING` はシアン、`DONE` は緑
- 差分がないときは再描画しない
- 端末サイズに応じて表示行数を再計算

### tmux-follow-claude-pane `<session> <pane_id> [status] [title]`

単一ペインの出力を `less -R +F` で追跡する。

- `Ctrl+C` で follow 停止
- `F` で follow 再開
- `q` で終了
- pane reset / pane close をログに追記

### tmux-select-claude-session

`$CLAUDE_TMUX_SESSION_INFO_DIR` を元にアクティブな ai-orchestra セッションを選択する。

- 候補が 1 件なら自動選択
- 複数件なら fzf で選択

### tmux-select-claude-pane `<session>`

セッション内のペインを選択する。

- 出力形式: `pane_id<TAB>status<TAB>title`
- プレビューには末尾 120 行を表示

### tmux-toggle-claude

右 40% に AI 監視ペインを表示し、同じタイトル (`claude-watch`) のペインがあれば閉じる。

---

## Claude pane ダッシュボード

Claude Code を実行している tmux pane を、セッション単位ではなく pane 単位で扱うためのスクリプト群。

### 呼出フロー

```
Prefix+b
  └→ tmux-popup-claude-dashboard
       ├→ tmux-list-claude-panes
       └→ tmux-open-claude-target
```

### tmux-list-claude-panes

全 tmux pane を走査し、Claude Code を実行している pane だけを TSV で出力する。

- `session<TAB>window<TAB>pane_index<TAB>pane_id<...>` の形式で出力
- 未アタッチの `claude-*-<digits>` session は既定で除外
- `TMUX_CLAUDE_INCLUDE_HOOK_SESSIONS=1` で hook session も含められる
- status は pane 末尾の prompt / 承認待ち表現から推定する

### tmux-popup-claude-dashboard

`fzf` popup で Claude Code pane を横断選択する。

- 候補は pane 単位で表示
- preview には scrollback 末尾 160 行を表示
- `Ctrl-R` で一覧を再読込

### tmux-open-claude-target

popup 内で選んだ target を受け取り、popup 終了後に親クライアント側で session / window / pane を切り替える。

---

## スナップショット系

### tmux-save-pane-snapshot `[pane-id]`

ペインズーム時 (`Prefix+z`, `pane_mode` の `z`) に自動呼出される。

- 保存先: `~/.cache/tmux/pane-snapshots/`
- alternate screen と history buffer の両方をキャプチャ
- メタデータ (セッション名, コマンド, パスなど) を記録

### tmux-open-pane-snapshot `[pane-id]`

保存済みスナップショットを `less -R` で表示する。

- `Prefix+V` から popup で呼び出される

---

## セッション管理系 (Phase 2)

### tmux-sessionizer

GHQ リポジトリ + git worktree を fzf で選択し、tmux セッション作成/切替する。

- `repo-list.sh` の TYPE でアイコンを分岐: `repo` → `○ 📦`, `worktree` → `● 🔀`
- 現在のセッションに `(current)` マーカー付与
- セッション名: worktree は `repo:branch`, repo は末尾ディレクトリ名 (`.` → `-`)
- キーバインド: `Prefix + f`

### tmux-kill-session

fzf でセッション選択 → 削除。プレビューにウィンドウ一覧を表示。

- 現在のセッションと `claude-*` は除外
- キーバインド: `Prefix + W`

---

## 補助スクリプト

### tmux-switch-session `<N>`

N 番目の非 Claude セッションへ切り替える。

- 現在の `session.conf` では未バインド
- 直接 `tmux-switch-session 2` のように手動で使える

### tmux-popup-claude

AI 監視セッションを popup で開く入口。

- 現在のキーバインドからは呼ばれない
- 手動実行や将来の popup 導線用に残している

---

## 未実装 (移行計画で追加予定)

| スクリプト | 概要 | Phase |
|-----------|------|-------|
| tmux-init-panes | ペイン数に応じて AI ツール自動起動 | 4 |
| tmux-baton-status | baton ステータス取得 | 4 |
| tmux-command-menu | コマンドパレット (fzf) | 5 |
