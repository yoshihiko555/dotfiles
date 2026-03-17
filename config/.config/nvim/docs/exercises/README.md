# Neovim 練習ガイド

このディレクトリの練習ファイルを Neovim で開き、指示に従って操作することでキーバインドを身につける。

## 学習プログレッション

### Phase A: 編集の基礎固め（順番通り）

1. [01-editing-basics.md](01-editing-basics.md) — 基本編集 (d/c/y/p/.)
2. [02-text-objects.md](02-text-objects.md) — テキストオブジェクト (i/a + w/"/(/{ etc.)
3. [03-visual-mode.md](03-visual-mode.md) — Visual モード (v/V/Ctrl+v)

### Phase B: 効率化テクニック（任意の順序）

4. [04-registers-marks.md](04-registers-marks.md) — レジスタ・マーク
5. [05-search-replace.md](05-search-replace.md) — 検索・置換
6. [06-surround-comment.md](06-surround-comment.md) — nvim-surround + Comment.nvim

### Phase C: プラグイン活用（任意の順序）

7. [07-neo-tree.md](07-neo-tree.md) — Neo-tree ファイル操作
8. [08-fzf-lua.md](08-fzf-lua.md) — FzfLua 検索ワークフロー

### Phase D: 開発ワークフロー（Phase C 完了後）

9. [09-lsp-workflow.md](09-lsp-workflow.md) — LSP 操作
10. [10-git-workflow.md](10-git-workflow.md) — Git hunk/diff ワークフロー

## 使い方

1. Neovim で練習ファイルを開く: `nvim docs/exercises/01-editing-basics.md`
2. 各練習の指示に従い、ファイル内で直接操作する
3. 確認テストのチェックリストで習得度を確認
4. 次の Exercise へ進む

## 注意

- 練習ファイルは自由に編集してよい（`git checkout` で元に戻せる）
- プラグイン系 (07-10) はファイル内の指示に従い、実際のプロジェクトで操作する
