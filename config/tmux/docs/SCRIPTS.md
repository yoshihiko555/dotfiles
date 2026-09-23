# ヘルパースクリプト

`bin/` 配下のスクリプト一覧。全て `~/.config/tmux/bin/` にインストールされる。

## 現在の使用状況

| スクリプト | 状態 | 使用箇所 | 概要 |
|-----------|------|----------|------|
| tmux-apply-statusbar | 現役 | `statusbar.conf` | Powerline 付き `window-status-format` を適用 |
| tmux-status-right | 現役 | `statusbar.conf` | baton サマリ + プロジェクト + 日時を右側に描画 |
| tmux-save-pane-snapshot | 現役 | `keybinds.conf`, `pane-mode.conf` | ペイン内容のスナップショット保存 |
| tmux-split-layout | 現役 | `keybinds.conf` (`Prefix+2-8`) | 現在ウィンドウを N ペインに分割 |
| tmux-launch-claude-work | 現役 | Loupedeck (tmux キーバインドなし) | 全ペインで会社用 Claude Code を auto モード起動 |
| tmux-open-pane-snapshot | 現役 | `copy-mode.conf` | 保存済みスナップショットを popup で表示 |
| ~~tmux-list-claude-panes~~ | 撤去 | - | baton に移行済み |
| ~~tmux-popup-claude-dashboard~~ | 撤去 | - | baton に移行済み |
| ~~tmux-open-claude-target~~ | 撤去 | - | baton に移行済み |
| tmux-init-panes | 現役 | `keybinds.conf` (`Prefix+0`) | ペイン数に応じて nvim / claude / codex を起動 |
| tmux-cheatsheet-preview | 現役 | `popup.conf` (`Prefix+.`) | チートシート (トピック一覧 + glow プレビュー) |
| tmux-sessionizer | 現役 | `popup.conf` (`Prefix+f`) | GHQ リポジトリ + worktree の picker |
| tmux-kill-session | 現役 | `popup.conf` (`Prefix+W`) | fzf でセッションを選んで削除 |
| tmux-kill-current-session | 現役 | `keybinds.conf` (`Prefix+X`) | 現在のセッションを確認付きで削除 |
| ~~ai-orchestra 監視系 8 本 / tmux-popup-claude / tmux-switch-session~~ | 撤去 | - | 2026-09-23 撤去（監視データが生成されなくなっていた） |
| ~~tmux-cheatsheet~~ | 撤去 | - | 2026-09-23 撤去。`tmux-cheatsheet-preview` に一本化 |

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

右側に baton の軽量サマリ（`baton --once --format tmux`）、プロジェクト名、日時を描画する。

- セッション名に `:` を含む場合は worktree アイコン
- それ以外は repo アイコン
- 日時は `MM/DD HH:MM` 形式

---

## Claude Code セッション管理 (baton)

`Prefix+B` で `baton --exit` を popup 起動 (90x90%)。`Prefix+b` は常駐の default セッションへ切替。
旧暫定ダッシュボードスクリプト (`tmux-popup-claude-dashboard`, `tmux-list-claude-panes`, `tmux-open-claude-target`) は撤去済み。

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

## ペイン一括起動

### tmux-launch-claude-work `[pane_id]`

対象ウィンドウの全ペインへ `ccw --permission-mode auto` を送り、会社用 Claude Code を
auto モードで一斉起動する。`Prefix+8` で 8 分割したあと Loupedeck のボタンで押す想定で、
tmux 側のキーバインドは意図的に持たない。

- 省略時は最後に操作した tmux クライアントのアクティブウィンドウが対象。
  Loupedeck の「アプリを実行」にこのスクリプトの絶対パスを登録して呼ぶ
  (TTY なし・`TMUX` なしで動くよう PATH を自前で補っている)
- `pane_id` を渡すとそのウィンドウが対象 (検証・手動実行用)
- `pane_current_command` がシェル (zsh/bash/fish/sh) のペインにだけ送る。
  claude / nvim 等が動いているペインはスキップし、結果をステータス行
  (tmux 外からは macOS 通知) に出す
- 検証時は `TMUX_LAUNCH_SOCKET=<name>` で `tmux -L` の別サーバーに向け、
  `TMUX_CLAUDE_WORK_CMD='echo ok'` で実コマンドを差し替える

---

## 未実装 (移行計画で追加予定)

| スクリプト | 概要 | Phase |
|-----------|------|-------|
| ~~tmux-baton-status~~ | baton TUI に統合済み。不要 | - |
| tmux-command-menu | コマンドパレット (fzf) | 5 |
