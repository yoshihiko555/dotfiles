# Neovim Docs

プラグイン導入に関するリサーチ・検証メモと意思決定ログ。

## ディレクトリ構成

```
docs/
├── README.md              # このファイル
├── research/              # プラグインのリサーチ・検証メモ
│   └── TEMPLATE.md        # リサーチメモのテンプレート
└── adr/                   # 意思決定ログ（ADR: Architecture Decision Records）
```

## research/

プラグインの調査・比較・検証結果を残す。
ファイル名: `{phase}-{topic}.md`（例: `p1-colorscheme.md`, `p1-fuzzy-finder.md`）

## adr/

なぜそのプラグインを選んだか、なぜ採用/不採用としたかの記録。
ファイル名: `{連番}-{タイトル}.md`（例: `001-colorscheme-selection.md`）
