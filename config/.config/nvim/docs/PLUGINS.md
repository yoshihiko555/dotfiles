# プラグイン一覧

導入済みプラグインの一覧。なぜ入れたのか・何をしているのかを記録する。

## Phase 1: 見た目 & ナビゲーション

| プラグイン | 設定ファイル | 用途 | 導入理由 |
|-----------|-------------|------|---------|
| [tokyonight.nvim](https://github.com/folke/tokyonight.nvim) | `plugins/colorscheme.lua` | カラースキーム（moon テーマ） | WezTerm と統一した配色でモチベーション維持 |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | `plugins/treesitter.lua` | 構文解析ベースのハイライト・インデント | 正規表現ベースより正確なシンタックスハイライトを実現 |
| [fzf-lua](https://github.com/ibhagwan/fzf-lua) | `plugins/fzf-lua.lua` | ファジーファインダー（ファイル検索・grep・LSP連携） | 素早いファイル移動・コード検索で編集効率を確保 |
| [lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) | `plugins/lualine.lua` | ステータスライン | モード・ブランチ・ファイル情報を常時表示 |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | `plugins/which-key.lua` | キーマップのリアルタイム表示 | Vim キーバインドの学習補助 |
| [neo-tree.nvim](https://github.com/nvim-neo-tree/neo-tree.nvim) | `plugins/neo-tree.lua` | ファイルエクスプローラー | VSCode のサイドバーに相当するファイルツリー |
| [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | — （依存として自動導入） | ファイルアイコン表示 | lualine / neo-tree / alpha 等のアイコン表示に必要 |
| [alpha-nvim](https://github.com/goolord/alpha-nvim) | `plugins/alpha.lua` | 起動画面（ダッシュボード） | よく使う操作への素早いアクセスと見た目の演出 |

## Phase 2: 編集効率

| プラグイン | 設定ファイル | 用途 | 導入理由 |
|-----------|-------------|------|---------|
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | `plugins/cmp.lua` | 補完エンジン | 入力中に自動で補完候補をポップアップ表示する。VSCode の補完体験に相当 |
| [cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp) | `plugins/cmp.lua`（依存） | LSP 補完ソース | LSP サーバーの補完候補を nvim-cmp に渡す橋渡し |
| [cmp-buffer](https://github.com/hrsh7th/cmp-buffer) | `plugins/cmp.lua`（依存） | バッファ補完ソース | 現在開いているファイル内の単語を補完候補に追加 |
| [cmp-path](https://github.com/hrsh7th/cmp-path) | `plugins/cmp.lua`（依存） | パス補完ソース | ファイルパスの入力を補完 |
| [cmp-cmdline](https://github.com/hrsh7th/cmp-cmdline) | `plugins/cmp.lua`（依存） | コマンドライン補完ソース | `:` `/` `?` のコマンドライン入力を補完 |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) | `plugins/cmp.lua`（依存） | スニペットエンジン | スニペットの展開・Tab でのジャンプを担当。nvim-cmp に必須 |
| [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) | `plugins/cmp.lua`（依存） | 汎用スニペット集 | 各言語の定型コード（if, for, func 等）を即座に展開 |
| [cmp_luasnip](https://github.com/saadparwaiz1/cmp_luasnip) | `plugins/cmp.lua`（依存） | LuaSnip 補完ソース | LuaSnip のスニペットを nvim-cmp の補完候補に表示 |
| [nvim-autopairs](https://github.com/windwp/nvim-autopairs) | `plugins/autopairs.lua` | 括弧・引用符の自動ペア | `(` `"` `{` 等の入力時に自動で閉じる。nvim-cmp と連携し補完確定時もペアを閉じる |
| [Comment.nvim](https://github.com/numToStr/Comment.nvim) | `plugins/comment.lua` | コメントトグル（gcc / gc） | 行・範囲・ブロックコメントを素早く切り替え。treesitter で言語ごとのコメント記号を自動判定 |
| [nvim-surround](https://github.com/kylechui/nvim-surround) | `plugins/surround.lua` | 囲み文字の操作（ys / ds / cs） | 括弧・引用符・タグの追加・変更・削除を素早く行う |

## その他

| プラグイン | 設定ファイル | 用途 | 導入理由 |
|-----------|-------------|------|---------|
| [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) | `plugins/render-markdown.lua` | Markdown のエディタ内プレビュー | 見出し・リスト等をエディタ内で装飾表示 |
| [markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) | `plugins/markdown-preview.lua` | Markdown のブラウザプレビュー | Mermaid 等を含む Markdown をブラウザでリアルタイムプレビュー |

## コア設定（プラグイン外）

| ファイル | 用途 |
|---------|------|
| `core/lsp.lua` | 組み込み LSP の設定（gopls / pyright / tsserver の起動・キーマップ・diagnostics） |
| `core/keymaps.lua` | 一般キーマップ（ウィンドウ移動・バッファ操作・quickfix） |
| `core/options.lua` | Neovim 基本オプション（行番号・インデント・検索等） |
