# WezTerm Keybindings Cheatsheet (tmux-first)

WezTerm は GUI レンダラーに限定。タブ/ペイン/セッション管理は tmux 側。

## tmux 操作 (Cmd → tmux に変換)

| Key | tmux 操作 |
|-----|----------|
| `Cmd+1-8` | ウィンドウ切替 (Alt+1-8 に変換) |
| `Cmd+t` | 新規ウィンドウ (Prefix+c に変換) |
| `Cmd+d` | ペイン横分割 (Prefix+r に変換) |
| `Cmd+Shift+d` | ペイン縦分割 (Prefix+d に変換) |
| `Cmd+w` | ペイン閉じ (Prefix+x に変換) |

## Copy / Search

| Key | Action |
|-----|--------|
| `Cmd+c` / `Cmd+v` | コピー/ペースト |
| `Ctrl+Shift+x` | Copy Mode (vim風) |
| `Cmd+f` | 検索 |
| `Ctrl+Shift+u` | 文字選択 (絵文字等) |

## Font

| Key | Action |
|-----|--------|
| `Cmd+=` | フォント拡大 |
| `Cmd+-` | フォント縮小 |
| `Cmd+0` | フォントリセット |

## Scroll

| Key | Action |
|-----|--------|
| `Shift+PageUp/Down` | ページスクロール |
| `Cmd+k` | スクロールバッククリア |

## Window / App

| Key | Action |
|-----|--------|
| `Cmd+n` | 新規ウィンドウ |
| `Alt+Enter` | フルスクリーン |
| `Cmd+r` | 設定リロード |
| `Cmd+Shift+p` | コマンドパレット |
| `Ctrl+Shift+l` | デバッグオーバーレイ |
| `Cmd+h` | アプリ隠す |
| `Cmd+m` | 最小化 |
| `Cmd+q` | 終了 |

## Copy Mode (vim)

| Key | Action |
|-----|--------|
| `h/j/k/l` | カーソル移動 |
| `w/b/e` | 単語移動 |
| `0/$` | 行頭/行末 |
| `g/G` | 先頭/末尾 |
| `f/F/t/T` | 行内ジャンプ |
| `Ctrl+f/b` | ページ移動 |
| `Ctrl+d/u` | 半ページ移動 |
| `v` | 選択 |
| `V` | 行選択 |
| `Ctrl+v` | 矩形選択 |
| `y` | コピー&終了 |
| `q/Esc` | 終了 |

## Search Mode

| Key | Action |
|-----|--------|
| `Enter` | 前の一致 |
| `Ctrl+n/p` | 次/前の一致 |
| `Ctrl+r` | 検索タイプ切替 |
| `Ctrl+u` | パターンクリア |
| `Esc` | 終了 |
