# ヘルパースクリプト

`bin/` 配下のスクリプト一覧。全て `~/.config/tmux/bin/` にインストールされる。

## 呼び出し元と用途

| スクリプト | 使用箇所 | 概要 |
|-----------|----------|------|
| [tmux-apply-statusbar](../bin/tmux-apply-statusbar) | `statusbar.conf` | Powerline 付き `window-status-format` を適用 |
| [tmux-status-right](../bin/tmux-status-right) | `statusbar.conf` | baton サマリ + プロジェクト + 日時を右側に描画 |
| [tmux-save-pane-snapshot](../bin/tmux-save-pane-snapshot) | `keybinds.conf`, `pane-mode.conf` | ペイン内容のスナップショット保存 |
| [tmux-split-layout](../bin/tmux-split-layout) | `keybinds.conf` (`Prefix+2-8`) | 現在ウィンドウを N ペインに分割 |
| [tmux-launch-claude-work](../bin/tmux-launch-claude-work) | Loupedeck (tmux キーバインドなし) | 全ペインで会社用 Claude Code を一斉起動 |
| [tmux-open-pane-snapshot](../bin/tmux-open-pane-snapshot) | `copy-mode.conf` | 保存済みスナップショットを popup で表示 |
| [tmux-init-panes](../bin/tmux-init-panes) | `keybinds.conf` (`Prefix+0`) | ペイン数に応じて nvim / claude / codex を起動 |
| [tmux-cheatsheet-preview](../bin/tmux-cheatsheet-preview) | `popup.conf` (`Prefix+.`) | チートシート (トピック一覧 + glow プレビュー) |
| [tmux-sessionizer](../bin/tmux-sessionizer) | `popup.conf` (`Prefix+f`) | GHQ リポジトリ + worktree の picker |
| [tmux-kill-session](../bin/tmux-kill-session) | `popup.conf` (`Prefix+W`) | fzf でセッションを選んで削除 |
| [tmux-kill-current-session](../bin/tmux-kill-current-session) | `keybinds.conf` (`Prefix+X`) | 現在のセッションを確認付きで削除 |

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

## セッション管理

### tmux-sessionizer

GHQ リポジトリ + git worktree を fzf で選択し、tmux セッション作成/切替する。

- `repo-list.sh` の TYPE でアイコンを分岐: `repo` は白丸とリポジトリアイコン、`worktree` は黒丸とブランチアイコン
- 現在のセッションに `(current)` マーカー付与
- セッション名: 通常のリポジトリは末尾ディレクトリ名を使い、名前の `.` は `-` に置き換える
- キーバインド: `Prefix + f`

### tmux-kill-session

fzf でセッション選択 → 削除。プレビューにウィンドウ一覧を表示。

- 現在のセッションと `claude-*` は除外
- キーバインド: `Prefix + W`

---

## ペイン一括起動

### tmux-launch-claude-work `[pane_id]`

対象ウィンドウの全ペインへ `ccw` を送り、会社用 Claude Code を一斉起動する。
起動モードは `claude-work/settings.json` の `permissions.defaultMode`（現在は `auto`）に従う。`Prefix+8` で 8 分割したあと Loupedeck のボタンで押す想定で、
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
