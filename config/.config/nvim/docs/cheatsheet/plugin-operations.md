# プラグイン内部操作

## Neo-tree (ファイルエクスプローラ)

`<leader>e` で開く / `<leader>E` で現在のファイルを表示

### ナビゲーション

| キー | 説明 |
|------|------|
| `j` / `k` | 上下移動 |
| `Enter` / `o` | ファイルを開く / ディレクトリ展開 |
| `S` | 水平分割で開く |
| `s` | 垂直分割で開く |
| `t` | 新しいタブで開く |
| `<BS>` (Backspace) | 親ディレクトリへ移動 |
| `P` | プレビュー表示 |

### ファイル操作

| キー | 説明 |
|------|------|
| `a` | 新規作成 (末尾 `/` でディレクトリ) |
| `d` | 削除 |
| `r` | リネーム |
| `c` | コピー |
| `m` | 移動 |
| `y` | パスをコピー (yank) |
| `x` | カット |
| `p` | ペースト |

### 表示切替

| キー | 説明 |
|------|------|
| `H` | 隠しファイル表示 toggle |
| `R` | リフレッシュ |
| `/` | フィルター |
| `z` | すべてのノードを閉じる |
| `q` | Neo-tree を閉じる |
| `?` | ヘルプ表示 |

## FzfLua (ファジーファインダー)

検索ウィンドウ内で使えるキー (Insert モード):

| キー | 説明 |
|------|------|
| `Enter` | 選択を開く |
| `Ctrl+v` | 垂直分割で開く |
| `Ctrl+x` | 水平分割で開く |
| `Ctrl+t` | 新しいタブで開く |
| `Ctrl+j` / `Ctrl+k` | 結果リストを上下移動 |
| `Ctrl+n` / `Ctrl+p` | 結果リストを上下移動 |
| `Ctrl+d` / `Ctrl+u` | プレビューをスクロール |
| `Ctrl+q` | 結果を Quickfix に送る |
| `Tab` | 複数選択 toggle |
| `Shift+Tab` | 複数選択 toggle (逆方向) |
| `Ctrl+a` | すべて選択 |
| `Esc` / `Ctrl+c` | 検索を閉じる |

### 検索トグル（ピッカー内で検索条件を切り替え）

| キー | 説明 |
|------|------|
| `Alt+h` | 隠しファイル（dotfiles）の表示/非表示を切り替え |
| `Alt+i` | `.gitignore` の尊重/無視を切り替え |
| `Alt+f` | シンボリックリンク先の追跡を切り替え |
| `Ctrl+g` | grep ↔ live_grep の切り替え（grep系コマンドのみ） |
| `Alt+a` | 全選択の toggle |

## Alpha ダッシュボード

起動画面で使えるキー:

| キー | 説明 |
|------|------|
| `e` | 新規ファイル |
| `f` | ファイル検索 |
| `r` | 最近のファイル |
| `g` | Grep 検索 |
| `x` | ファイルエクスプローラ |
| `i` | init.lua を編集 |
| `q` | 終了 |

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
| gitsigns.nvim | Git 変更表示・hunk操作・inline blame |
| codediff.nvim | VSCode風 diff viewer（文字レベルハイライト） |
| smart-splits.nvim | Neovim ↔ tmux シームレスペイン移動・リサイズ |
| copilot.lua | GitHub Copilot AI 補完 |
