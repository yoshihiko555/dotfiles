# Neovim Docs

プラグイン導入に関するリサーチ・検証メモと意思決定ログ。

## ディレクトリ構成

```
docs/
├── README.md              # このファイル
├── PLUGINS.md             # プラグイン一覧（用途・導入理由）
├── cheatsheet/            # キーバインド・操作チートシート（トピック別）
│   ├── README.md          # 目次
│   ├── vim-basics.md      # モード/移動/検索/編集/コマンドライン
│   ├── text-objects.md    # オペレータ+テキストオブジェクト / Visual
│   ├── registers-marks.md # レジスタ / マーク
│   ├── custom-keybinds.md # カスタムキーバインド全般
│   ├── plugin-operations.md # Neo-tree/FzfLua/Alpha 内部操作
│   └── git-workflow.md    # gitsigns/CodeDiff/Git操作
├── exercises/             # ハンズオン練習ファイル
│   ├── README.md          # 練習ガイド・プログレッション
│   ├── 01-editing-basics.md
│   ├── 02-text-objects.md
│   ├── 03-visual-mode.md
│   ├── 04-registers-marks.md
│   ├── 05-search-replace.md
│   ├── 06-surround-comment.md
│   ├── 07-neo-tree.md
│   ├── 08-fzf-lua.md
│   ├── 09-lsp-workflow.md
│   └── 10-git-workflow.md
├── research/              # プラグインのリサーチ・検証メモ
│   └── TEMPLATE.md        # リサーチメモのテンプレート
└── adr/                   # 意思決定ログ（ADR: Architecture Decision Records）
```

## cheatsheet/

トピック別に分割したキーバインド・操作リファレンス。
→ [目次](cheatsheet/README.md)

## exercises/

Neovim で開いて指示に従い操作するハンズオン練習ファイル。
→ [練習ガイド](exercises/README.md)

## research/

プラグインの調査・比較・検証結果を残す。
ファイル名: `{phase}-{topic}.md`（例: `p1-colorscheme.md`, `p1-fuzzy-finder.md`）

## adr/

なぜそのプラグインを選んだか、なぜ採用/不採用としたかの記録。
ファイル名: `{連番}-{タイトル}.md`（例: `001-colorscheme-selection.md`）
