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
| `<leader>wd` / `<leader>w<C-d>` | カーソル位置の診断を表示 |

## バッファ (`<leader>b`)

| キー | 説明 |
|------|------|
| `<leader>bn` | 次のバッファ |
| `<leader>bp` | 前のバッファ |
| `<leader>bd` | バッファ削除 |

## ファイルエクスプローラ Neo-tree

| キー | 説明 |
|------|------|
| `<leader>e` | Neo-tree を開く / 閉じる |
| `<leader>E` | 現在のファイルを Neo-tree 上で表示 |

## ファイル検索 FzfLua (`<leader>f`)

| キー | 説明 |
|------|------|
| `<leader>ff` | ファイル検索 |
| `<leader>fg` | Grep 検索 |
| `<leader>fb` | バッファ検索 |
| `<leader>fh` | Help 検索 |
| `<leader>fr` | 最近のファイル |
| `<leader>fd` | Diagnostics |

## Git (`<leader>g`)

| キー | 説明 |
|------|------|
| `<leader>gc` | Git commits |
| `<leader>gs` | Git status |

## フォーマット

| キー | 説明 |
|------|------|
| `<leader>cf` | 現在のバッファをフォーマット |

保存時にも対応するフォーマッタ、または LSP によるフォーマットを自動実行する。

## 補完 nvim-cmp（Insert / Select モード）

| キー | 説明 |
|------|------|
| `Ctrl+Space` | 補完候補を表示 |
| `Enter` | 選択中の候補を確定 |
| `Tab` / `Shift+Tab` | 次/前の候補、またはスニペット位置へ移動 |
| `Ctrl+b` / `Ctrl+f` | 補完ドキュメントを上/下にスクロール |

## コメント・囲み文字

### Comment.nvim

| キー | モード | 説明 |
|------|--------|------|
| `gcc` | Normal | 現在行のコメントを toggle |
| `gbc` | Normal | 現在行のブロックコメントを toggle |
| `gc{motion}` | Normal | モーション範囲のコメントを toggle |
| `gc` / `gb` | Visual | 選択範囲の行/ブロックコメントを toggle |

### nvim-surround

| キー | モード | 説明 |
|------|--------|------|
| `ys{motion}{char}` | Normal | モーション範囲を囲む |
| `yss{char}` | Normal | 行全体を囲む |
| `ds{char}` | Normal | 囲み文字を削除 |
| `cs{old}{new}` | Normal | 囲み文字を変更 |
| `S{char}` | Visual | 選択範囲を囲む |

## Quickfix (`<leader>x`)

| キー | 説明 |
|------|------|
| `]q` / `[q` | 次/前の quickfix |
| `<leader>xq` | Quickfix 開く |
| `<leader>xc` | Quickfix 閉じる |
| `<leader>xl` | Location list 開く |
| `<leader>xL` | Location list 閉じる |
| `<leader>xd` | Diagnostics → quickfix |

## Trouble（診断一覧 — `<leader>x`）

| キー | 説明 |
|------|------|
| `<leader>xx` | Diagnostics（ワークスペース全体） |
| `<leader>xX` | Diagnostics（現在バッファのみ） |

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

## TODO コメント

| キー | 説明 |
|------|------|
| `]t` / `[t` | 次/前の TODO へジャンプ |
| `<leader>st` | TODO を fzf-lua で横断検索 |

## その他

| キー | 説明 |
|------|------|
| `<leader>?` | バッファローカルキーマップ表示 (which-key) |
