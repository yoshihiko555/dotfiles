# Phase 1: which-key.nvim

## 背景

Vim操作の学習段階にあるため、キーマップをリアルタイムで表示して学習を補助したい。
また、今後プラグインが増えるにつれキーマップが増えるため、グループで整理する基盤が必要。

## 動作の仕組み

- `vim.keymap.set()` で `desc` 付きのキーマップを**自動検出**して表示
- グループラベル（`<leader>f` = "Find" 等）は手動登録が必要
- 組み込みpresets（g, z, [], operators, motions等）のヘルプも表示可能

## 既存キーマップとの互換性

core/lsp.lua のキーマップは全て `desc` 付きなので、追加設定なしで自動表示される。

## 将来のキーマップ設計

```
<Space>
├── f  → Find (Telescope)
├── g  → Git (gitsigns等)
├── c  → Code (LSP)
├── b  → Buffer
├── w  → Window (proxy → <C-w>)
└── ?  → Buffer Local Keymaps
```

既存の `<leader>rn`, `<leader>ca`, `<leader>e` はそのまま維持。
グループへの再配置は操作に慣れてから検討する。

## 設定ポイント

- `event = "VeryLazy"` で遅延読み込み
- `preset = "helix"` or `"classic"` は好みで選択
- presets（operators, motions, text_objects等）は学習段階では全て有効にする
- アイコンは nvim-web-devicons があれば自動で表示
