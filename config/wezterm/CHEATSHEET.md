# WezTerm のキー操作

通常起動で接続する tmux の Prefix は `Ctrl+Q`。起動時の動作と設定ファイルの場所は [WezTerm の README](README.md) を参照。

## tmux に送るショートカット

| キー | tmux での動作 |
|-----|----------|
| `Cmd+1-8` | ウィンドウ切替 (Alt+1-8 に変換) |
| `Cmd+t` | 新規ウィンドウ (Prefix+c に変換) |
| `Cmd+d` | ペイン横分割 (Prefix+r に変換) |
| `Cmd+Shift+d` | ペイン縦分割 (Prefix+d に変換) |
| `Cmd+w` | ペイン閉じ (Prefix+x に変換) |
| `Cmd+Shift+w` | セッションを閉じる（Prefix+X に変換。実行中のプロセスがあれば確認） |
| `Shift+Enter` | 改行 (`\n` を送る。takt 向けの送り分けは tmux 側) |

## クリップボードと文字選択

| キー | WezTerm での動作 |
|-----|--------|
| `Cmd+c` / `Cmd+v` | WezTerm の選択範囲をクリップボードにコピー / クリップボードから貼り付け |
| `Copy` / `Paste` | 専用キーで同じコピー / 貼り付け操作 |
| `Ctrl+Shift+u` | 文字選択 (絵文字等) |

スクロール履歴から範囲を選んでコピーするには、`Prefix + [` で tmux のコピーモードに入る。[tmux のコピーモード](../tmux/docs/CHEATSHEET.md#コピーモード)

## フォント

| キー | WezTerm での動作 |
|-----|--------|
| `Cmd+=` | フォント拡大 |
| `Cmd+-` | フォント縮小 |
| `Cmd+0` | フォントリセット |

## ウィンドウとアプリ

| キー | WezTerm での動作 |
|-----|--------|
| `Alt+Enter` | フルスクリーン |
| `Cmd+r` | 設定リロード |
| `Cmd+Shift+p` | コマンドパレット |
| `Ctrl+Shift+l` | デバッグオーバーレイ |
| `Cmd+h` | アプリ隠す |
| `Cmd+m` | 最小化 |
| `Cmd+q` | 終了 |
