# Neovim Plugin Roadmap

VSCode → Neovim 移行を段階的に進めるためのロードマップ。
Vim操作の習熟と並行して、フェーズごとにプラグインを追加していく。

## 対象言語

- Go, TypeScript, Python, Lua（設定ファイル用）

## フェーズ一覧

| Phase | テーマ | 目的 |
|-------|--------|------|
| 1 | 見た目 & ナビゲーション | 使い続けたくなる見た目と基本的なファイル操作 |
| 2 | 編集効率 | コード補完・スニペットなど書く速度を上げる |
| 3 | Git連携 | diff確認・blame・hunk操作をCLI上で完結 |
| 4 | LSP強化 & コード品質 | フォーマッタ・リンター・診断一覧 |
| 5 | デバッグ & テスト | DAP連携でIDE級のデバッグ環境 |
| 6 | 仕上げ | UI洗練・セッション管理・ダッシュボード |

---

## Phase 1: 見た目 & ナビゲーション

Vim操作を覚える段階。見た目を整えてモチベーションを維持しつつ、
ファイル移動・検索の基本操作を身につける。

| プラグイン | 用途 | 優先度 |
|-----------|------|--------|
| カラースキーム（候補: tokyonight, catppuccin, kanagawa） | 見た目の基盤 | 必須 |
| nvim-treesitter | シンタックスハイライト強化 | 必須 |
| telescope.nvim | ファジーファインダー（ファイル検索・grep・LSP連携） | 必須 |
| lualine.nvim | ステータスライン | 必須 |
| which-key.nvim | キーマップをリアルタイム表示（学習補助） | 推奨 |
| neo-tree.nvim or oil.nvim | ファイルエクスプローラー | 推奨 |
| nvim-web-devicons | ファイルアイコン表示 | 推奨 |

### 検証ポイント
- [ ] カラースキームが各言語で見やすいか
- [ ] telescope でファイル検索・grepが快適か
- [ ] which-key でキーマップを覚えやすいか

---

## Phase 2: 編集効率

日常的なコーディングの速度を上げるプラグイン群。
VSCodeの補完・スニペット体験に近づける。

| プラグイン | 用途 | 優先度 |
|-----------|------|--------|
| nvim-cmp + cmp-nvim-lsp | LSP補完 | 必須 |
| LuaSnip + friendly-snippets | スニペットエンジン + 汎用スニペット集 | 必須 |
| nvim-autopairs | 括弧・引用符の自動ペア | 推奨 |
| Comment.nvim | コメントトグル（gcc / gc） | 推奨 |
| nvim-surround | 囲み文字の操作（cs, ds, ys） | 推奨 |
| indent-blankline.nvim | インデントガイド表示 | 任意 |

### 検証ポイント
- [ ] LSP補完がスムーズに動作するか（Go / TS / Python / Lua）
- [ ] スニペット展開が自然か
- [ ] autopairsが邪魔にならないか

---

## Phase 3: Git連携

Claude Codeと並行してGit操作をCLI上で完結させる。
diffの確認やblameの参照をNeovim内で行えるようにする。

| プラグイン | 用途 | 優先度 |
|-----------|------|--------|
| gitsigns.nvim | 行ごとの変更表示・hunkステージ・blame | 必須 |
| diffview.nvim | diff/マージコンフリクトの視覚的確認 | 推奨 |
| neogit or fugitive.vim | Git操作UI | 任意 |

### 検証ポイント
- [ ] gitsignsのhunkナビゲーションが快適か
- [ ] diffviewでPR前のレビューができるか

---

## Phase 4: LSP強化 & コード品質

現在の手動LSP設定を発展させ、フォーマッタ・リンターを統合する。

| プラグイン | 用途 | 優先度 |
|-----------|------|--------|
| mason.nvim + mason-lspconfig | LSPサーバーの自動インストール・管理 | 必須 |
| nvim-lspconfig | LSP設定の簡略化 | 必須 |
| conform.nvim | フォーマッタ統合（保存時自動フォーマット） | 必須 |
| nvim-lint | リンター統合 | 推奨 |
| trouble.nvim | 診断・参照の一覧表示 | 推奨 |
| todo-comments.nvim | TODO/FIXME/HACKの強調・検索 | 任意 |

### 検証ポイント
- [ ] mason経由でgopls, pyright, ts_lsが自動インストールされるか
- [ ] 保存時フォーマットが各言語で動作するか
- [ ] 既存のlsp.luaからの移行がスムーズか

### 注意
- 現在の`core/lsp.lua`は組み込みLSP設定。mason/lspconfig導入時に統合が必要

---

## Phase 5: デバッグ & テスト

IDE級の最終ピース。ブレークポイント・ステップ実行をNeovim内で行う。

| プラグイン | 用途 | 優先度 |
|-----------|------|--------|
| nvim-dap | デバッグアダプタープロトコル | 必須 |
| nvim-dap-ui | デバッグUI | 必須 |
| nvim-dap-go | Go用DAP設定 | 必須 |
| neotest | テストランナー統合 | 推奨 |
| toggleterm.nvim | ターミナル統合（テスト実行用） | 推奨 |

### 検証ポイント
- [ ] Goのデバッグ（delve連携）が動作するか
- [ ] ブレークポイント設定・ステップ実行が使えるか
- [ ] テスト結果がNeovim内で確認できるか

---

## Phase 6: 仕上げ

細かいUI改善と利便性向上。

| プラグイン | 用途 | 優先度 |
|-----------|------|--------|
| noice.nvim | コマンドライン・通知のUI改善 | 任意 |
| alpha-nvim or dashboard-nvim | 起動画面 | 任意 |
| auto-session or persistence.nvim | セッション管理（前回の状態復元） | 推奨 |
| nvim-notify | 通知のリッチ表示 | 任意 |

---

## 進め方

1. 各フェーズごとにブランチで作業 → 検証 → mainにマージ
2. 検証ポイントをクリアしてから次のフェーズへ
3. 各プラグインは`lua/plugins/`配下に個別ファイルとして追加
   ```
   lua/plugins/
   ├── colorscheme.lua
   ├── treesitter.lua
   ├── telescope.lua
   └── ...
   ```
4. 問題があれば`enabled = false`で一時無効化して切り分け

## 現在の進捗

- [x] Phase 0: 基盤構築（lazy.nvim導入・モジュール分割・組み込みLSP設定）
- [ ] Phase 1: 見た目 & ナビゲーション ← **現在地**
- [ ] Phase 2: 編集効率
- [ ] Phase 3: Git連携
- [ ] Phase 4: LSP強化 & コード品質
- [ ] Phase 5: デバッグ & テスト
- [ ] Phase 6: 仕上げ
