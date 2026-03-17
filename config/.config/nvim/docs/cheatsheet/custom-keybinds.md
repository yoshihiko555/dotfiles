# カスタムキーバインド

**Leader: `Space`**

## 基本操作

| キー | モード | 説明 |
|------|--------|------|
| `jj` | Insert | Normal モードに戻る |
| `Esc` | Normal | 検索ハイライト解除 |

## ペイン移動 (smart-splits — Neovim ↔ tmux シームレス)

| キー | 説明 |
|------|------|
| `Alt+h` | 左ペイン |
| `Alt+j` | 下ペイン |
| `Alt+k` | 上ペイン |
| `Alt+l` | 右ペイン |

## ペインリサイズ (smart-splits)

| キー | 説明 |
|------|------|
| `Alt+Shift+H` | 左にリサイズ |
| `Alt+Shift+J` | 下にリサイズ |
| `Alt+Shift+K` | 上にリサイズ |
| `Alt+Shift+L` | 右にリサイズ |

## ウィンドウ操作 (`<leader>w` → `Ctrl+w` プロキシ)

which-key により `<leader>w` が `Ctrl+w` のプロキシとして動作:

| キー | 説明 |
|------|------|
| `<leader>ws` | 水平分割 (`:split`) |
| `<leader>wv` | 垂直分割 (`:vsplit`) |
| `<leader>wc` / `<leader>wq` | ウィンドウを閉じる |
| `<leader>wo` | 他のウィンドウをすべて閉じる |
| `<leader>ww` | 次のウィンドウへ移動 |
| `<leader>w=` | ウィンドウサイズを均等に |
| `<leader>w+` / `<leader>w-` | 高さを増減 |
| `<leader>w>` / `<leader>w<` | 幅を増減 |
| `<leader>wH/J/K/L` | ウィンドウを左/下/上/右に移動 |

## バッファ (`<leader>b`)

| キー | 説明 |
|------|------|
| `<leader>bn` | 次のバッファ |
| `<leader>bp` | 前のバッファ |
| `<leader>bd` | バッファ削除 |

## ファイル検索 FzfLua (`<leader>f`)

| キー | 説明 |
|------|------|
| `<leader>ff` | ファイル検索 |
| `<leader>fg` | Grep 検索 |
| `<leader>fb` | バッファ検索 |
| `<leader>fh` | Help 検索 |
| `<leader>fr` | 最近のファイル |
| `<leader>fd` | Diagnostics |
| `<leader>fs` | ドキュメントシンボル |
| `<leader>fw` | ワークスペースシンボル |

## Git (`<leader>g`)

| キー | 説明 |
|------|------|
| `<leader>gc` | Git commits |
| `<leader>gs` | Git status |

## LSP (`<leader>c` / `<leader>r` 系 — バッファアタッチ時のみ)

| キー | 説明 |
|------|------|
| `gd` | 定義へジャンプ |
| `gD` | 宣言へジャンプ |
| `gr` | 参照一覧 |
| `gi` | 実装へジャンプ |
| `K` | ホバー情報 |
| `<leader>rn` | リネーム |
| `<leader>ca` | コードアクション |
| `<leader>cd` | 行の Diagnostics |
| `[d` / `]d` | 前/次の Diagnostic |

**対応 LSP**: gopls, pyright, ts_ls

## Quickfix (`<leader>x`)

| キー | 説明 |
|------|------|
| `]q` / `[q` | 次/前の quickfix |
| `<leader>xq` | Quickfix 開く |
| `<leader>xc` | Quickfix 閉じる |
| `<leader>xl` | Location list 開く |
| `<leader>xL` | Location list 閉じる |
| `<leader>xd` | Diagnostics → quickfix |

## Markdown (`<leader>m`)

| キー | 説明 |
|------|------|
| `<leader>mp` | ブラウザプレビュー開始 |
| `<leader>mP` | ブラウザプレビュー停止 |
| `<leader>mr` | エディタ内レンダリング toggle |

## Copilot (AI 補完 — Insert モード)

| キー | モード | 説明 |
|------|--------|------|
| `Ctrl+y` | Insert | Copilot 提案を accept |
| `Ctrl+e` | Insert | Copilot 提案を dismiss |

## その他

| キー | 説明 |
|------|------|
| `<leader>?` | バッファローカルキーマップ表示 (which-key) |
