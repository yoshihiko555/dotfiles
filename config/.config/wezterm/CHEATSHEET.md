# WezTerm Keybindings Cheatsheet

Leader: `Ctrl+Q` (2s timeout)

## Pane Navigation

| Key              | Action                                   |
| ---------------- | ---------------------------------------- |
| `Alt+h/j/k/l`   | ペイン移動 (smart-splits.nvim 統合)      |
| `Alt+Shift+H/J/K/L` | ペインリサイズ (smart-splits.nvim 統合) |
| `Ctrl+Shift+矢印` | ペイン移動 (矢印キー)                  |
| `Ctrl+Shift+Alt+矢印` | ペインリサイズ (矢印キー)          |

## Leader Key (`Ctrl+Q`)

### Pane

| Key          | Action                     |
| ------------ | -------------------------- |
| `Leader d`   | 垂直分割                   |
| `Leader /`   | 水平分割                   |
| `Leader h/j/k/l` | ペイン移動 (vim風)    |
| `Leader H/J/K/L` | ペインリサイズ (vim風) |
| `Leader p`   | ペイン操作モード (連続)    |

### Overlay Pane (split + zoom)

| Key          | Action           |
| ------------ | ---------------- |
| `Leader g`   | lazygit          |
| `Leader y`   | yazi             |
| `Leader C`   | Claude Code      |
| `Leader t`   | 一時シェル (40%) |

### Workspace

| Key          | Action                         |
| ------------ | ------------------------------ |
| `Leader 8`   | 8分割タブ (4x2 grid)          |
| `Leader i`   | ワークスペース初期化           |
| `Leader c`   | チートシート表示 (Neovim)      |

## Pane Mode (`Leader p`)

| Key   | Action                      |
| ----- | --------------------------- |
| `h/j/k/l` | ペイン移動             |
| `H/J/K/L` | ペインリサイズ         |
| `d`   | 垂直分割                    |
| `/`   | 水平分割                    |
| `x`   | ペインを閉じる              |
| `z`   | ペインズーム                |
| `s`   | ペイン入替 (swap)           |
| `r`   | ペイン回転 (時計回り)       |
| `R`   | ペイン回転 (反時計回り)     |
| `g`   | overlay: lazygit            |
| `y`   | overlay: yazi               |
| `C`   | overlay: Claude Code        |
| `1-9` | ペイン番号で直接移動        |
| `q/Esc/Enter` | モード終了           |

## Tab

| Key                    | Action               |
| ---------------------- | -------------------- |
| `Cmd+t`                | 新規タブ (3ペイン)   |
| `Cmd+w`                | ペインを閉じる       |
| `Cmd+Shift+w`          | タブを閉じる         |
| `Cmd+1-9`              | タブ番号で移動       |
| `Ctrl+Tab`             | 次のタブ             |
| `Ctrl+Shift+Tab`       | 前のタブ             |
| `Cmd+{` / `Cmd+}`      | タブ移動             |
| `Ctrl+Shift+PageUp/Down` | タブ順序変更       |

## Split

| Key             | Action     |
| --------------- | ---------- |
| `Cmd+d`         | 水平分割   |
| `Cmd+Shift+d`   | 垂直分割   |
| `Ctrl+z`        | ズーム切替 |

## Copy / Search

| Key                | Action             |
| ------------------ | ------------------ |
| `Cmd+c` / `Cmd+v`  | コピー/ペースト   |
| `Ctrl+Shift+x`     | Copy Mode (vim風)  |
| `Ctrl+Shift+Space`  | QuickSelect       |
| `Cmd+f`            | 検索               |
| `Ctrl+Shift+u`     | 文字選択 (絵文字等) |

## Copy Mode (vim)

| Key        | Action       |
| ---------- | ------------ |
| `h/j/k/l`  | カーソル移動 |
| `w/b/e`    | 単語移動     |
| `0/$`      | 行頭/行末   |
| `g/G`      | 先頭/末尾    |
| `f/F/t/T`  | 行内ジャンプ |
| `Ctrl+f/b` | ページ移動   |
| `Ctrl+d/u` | 半ページ移動 |
| `v`        | 選択         |
| `V`        | 行選択       |
| `Ctrl+v`   | 矩形選択     |
| `y`        | コピー&終了  |
| `q/Esc`    | 終了         |

## Window / App

| Key              | Action               |
| ---------------- | -------------------- |
| `Cmd+n`          | 新規ウィンドウ       |
| `Alt+Enter`      | フルスクリーン       |
| `Cmd+r`          | 設定リロード         |
| `Ctrl+Shift+p`   | コマンドパレット     |
| `Ctrl+Shift+l`   | デバッグオーバーレイ |
| `Cmd+k`          | スクロールバッククリア |
| `Ctrl+l`         | 画面クリア (履歴保持) |
| `Cmd+q`          | 終了                 |
