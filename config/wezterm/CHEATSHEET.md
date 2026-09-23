# WezTerm Keybindings Cheatsheet (tmux 専用)

WezTerm はサブ端末で、常に tmux + baton で起動する。タブ/ペイン/セッション・スクロール・コピーは tmux 側
（[tmux のチートシート](../tmux/docs/CHEATSHEET.md)）。

## tmux 操作 (Cmd → tmux に変換)

| Key | tmux 操作 |
|-----|----------|
| `Cmd+1-8` | ウィンドウ切替 (Alt+1-8 に変換) |
| `Cmd+t` | 新規ウィンドウ (Prefix+c に変換) |
| `Cmd+d` | ペイン横分割 (Prefix+r に変換) |
| `Cmd+Shift+d` | ペイン縦分割 (Prefix+d に変換) |
| `Cmd+w` | ペイン閉じ (Prefix+x に変換) |
| `Cmd+Shift+w` | セッション閉じ (Prefix+X に変換、確認付き) |
| `Shift+Enter` | 改行 (`\n` を送る。takt 向けの送り分けは tmux 側) |

## Copy / 文字選択

| Key | Action |
|-----|--------|
| `Cmd+c` / `Cmd+v` | コピー/ペースト |
| `Ctrl+Shift+u` | 文字選択 (絵文字等) |

## Font

| Key | Action |
|-----|--------|
| `Cmd+=` | フォント拡大 |
| `Cmd+-` | フォント縮小 |
| `Cmd+0` | フォントリセット |

## Window / App

| Key | Action |
|-----|--------|
| `Alt+Enter` | フルスクリーン |
| `Cmd+r` | 設定リロード |
| `Cmd+Shift+p` | コマンドパレット |
| `Ctrl+Shift+l` | デバッグオーバーレイ |
| `Cmd+h` | アプリ隠す |
| `Cmd+m` | 最小化 |
| `Cmd+q` | 終了 |
