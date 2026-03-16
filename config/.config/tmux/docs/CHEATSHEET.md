# tmux キーバインド チートシート

Prefix: `Ctrl+T`

## 基本操作

| キー | 動作 |
|------|------|
| `Prefix + r` | 横分割 |
| `Prefix + d` | 縦分割 |
| `Prefix + x` | ペイン閉じ |
| `Prefix + z` | ペインズーム (スナップショット保存付き) |
| `Prefix + h/j/k/l` | ペイン移動 |
| `Alt + h/j/k/l` | ペイン移動 (smart-splits, Prefix 不要) |
| `Prefix + c` | 新しいウィンドウ |
| `Prefix + n` | 次のウィンドウ |
| `Prefix + P` | 前のウィンドウ |
| `Alt + 1-9` | 指定番号のウィンドウへ直接移動 |
| `Prefix + R` | 設定リロード |

## ペインモード (`Prefix + p`)

モード中は Prefix 不要で連続操作可能。`Escape` / `Enter` / `q` で抜ける。

| キー | 動作 |
|------|------|
| `h/j/k/l` | ペイン移動 |
| `r` | 横分割 |
| `d` | 縦分割 |
| `x` | ペイン閉じ |
| `z` | ズーム (スナップショット保存付き) |
| `1-5` | ペイン番号でジャンプ |
| `e` | リサイズモードに切替 |

## リサイズモード (`Prefix + e`)

| キー | 動作 |
|------|------|
| `h/j/k/l` | 5 セル単位でリサイズ |
| `H/J/K/L` | 1 セル単位でリサイズ |
| `Escape` / `Enter` / `q` | モード終了 |

## セッション / ポップアップ / AI

| キー | 動作 |
|------|------|
| `Prefix + s` | セッション一覧を popup + fzf で表示 |
| `Prefix + g` | lazygit popup (80x80%) |
| `Prefix + t` | 一時シェル popup (80x80%) |
| `Prefix + C` | Claude Code popup (90x90%) |
| `Prefix + a` | AI サブエージェント履歴 popup (90x90%) |
| `Prefix + A` | AI 監視ペインの表示 / 非表示 |

## コピーモード

| キー | 動作 |
|------|------|
| `Prefix + [` | コピーモード開始 |
| `Prefix + V` | ペインスナップショット表示 (95x95% popup) |
| マウスドラッグ | 選択開始 → コピー (コピーモード維持) |

### コピーモード詳細

- キーバインド体系は `vi`
  - `general.conf` で `set -g mode-keys vi`
- `Space` で通常の選択開始
- `v` で矩形選択の ON / OFF を切り替える
  - 現行設定では切替時に `矩形選択: ON/OFF` をメッセージ表示する
- `V` は現在行を選択する
- `Prefix + V` は別機能で、保存済み snapshot を popup で開く
- 画面のテキストをマウスドラッグすると、通常状態からでも `copy-mode` に入って選択を開始する
- ドラッグ終了時は `copy-selection` のみ実行する
  - コピーモードは維持される
  - スクロール位置も維持される
- `Prefix + z` または `pane_mode` の `z` で保存したスナップショットは `Prefix + V` で別 popup から確認できる
- コピー内容は tmux の copy buffer に入る
  - tmux 全体では `set-clipboard on` なので、OSC52 経由の clipboard 連携も有効

## ステータスバー左端のモード表示

| バッジ | 状態 |
|--------|------|
| `COPY` (黄) | コピーモード中 |
| `PANE` (緑) | ペインモード中 |
| `RESIZE` (青) | リサイズモード中 |
| `PREFIX` (青紫) | Prefix 入力直後 |

---

## 未実装 (移行計画で追加予定)

| キー (予定) | 動作 | Phase |
|------------|------|-------|
| `Prefix + f` | プロジェクト picker (tmux-sessionizer, repo/worktree アイコン付き) | 2 |
| `Prefix + W` | セッション削除 (tmux-kill-session) | 2 |
| `Prefix + F` | tmux-fingers (テキスト選択) | 3 |
| `Prefix + b` | claude-squad | 4 |
| `Prefix + Space` | コマンドパレット | 5 |
| `Prefix + u` | URL 選択 (urlscan) | 5 |
