# Neovim Cheatsheet

**Leader: `Space`** | Theme: tokyonight (moon) | Plugin Manager: lazy.nvim

## 基本操作

| キー | モード | 説明 |
|------|--------|------|
| `jj` | Insert | Insert モード脱出 |
| `Esc` | Normal | 検索ハイライト解除 |

## ウィンドウ移動

| キー | 説明 |
|------|------|
| `Ctrl+h` | 左ウィンドウ |
| `Ctrl+j` | 下ウィンドウ |
| `Ctrl+k` | 上ウィンドウ |
| `Ctrl+l` | 右ウィンドウ |

## バッファ (`<leader>b`)

| キー | 説明 |
|------|------|
| `<leader>bn` | 次のバッファ |
| `<leader>bp` | 前のバッファ |
| `<leader>bd` | バッファ削除 |

## ファイルエクスプローラ (Neo-tree)

| キー | 説明 |
|------|------|
| `<leader>e` | エクスプローラ toggle |
| `<leader>E` | 現在ファイルを reveal |

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

## LSP (バッファアタッチ時のみ)

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

**対応 LSP**: gopls, pyright, tsserver

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

## その他

| キー | 説明 |
|------|------|
| `<leader>?` | バッファローカルキーマップ表示 (which-key) |

## インストール済みプラグイン一覧

| プラグイン | 用途 |
|-----------|------|
| tokyonight.nvim | カラースキーム (moon) |
| nvim-treesitter | シンタックスハイライト・インデント |
| lualine.nvim | ステータスライン |
| alpha-nvim | ダッシュボード (サイバーパンク風) |
| fzf-lua | ファジーファインダー |
| neo-tree.nvim | ファイルエクスプローラ |
| which-key.nvim | キーバインドヘルプ |
| render-markdown.nvim | エディタ内 Markdown レンダリング |
| markdown-preview.nvim | ブラウザ Markdown プレビュー (Mermaid対応) |
