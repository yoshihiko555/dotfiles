# Phase 1: ファジーファインダー選定

## 背景

ファイル検索・grep・LSP連携などをNeovim内で完結させるためのファジーファインダーを選定する。

## 候補

| | telescope.nvim | fzf-lua | mini.pick |
|---|---|---|---|
| Stars | ~19.1k | ~4.1k | ~8.8k |
| Lua依存 | plenary.nvim必須 | なし | なし |
| 外部バイナリ | 不要 | fzf必須 | 不要 |
| 検索速度 | 普通（fzf-native入れれば速い） | 最速 | 良好 |
| 組み込みpicker数 | ~30 | ~70+ | ~10 |
| プラグイン連携 | 最多 | 増加中 | 少ない |

## 比較（telescope vs fzf-lua）

### telescope.nvim
- 強み: エコシステム最大、UIカスタマイズ豊富、情報量が多い
- 弱み: plenary.nvim依存、デフォルトソーターが遅い、normalモード不可

### fzf-lua
- 強み: 検索最速、Lua依存ゼロ、picker 70+内蔵、normalモード可
- 弱み: fzfバイナリ必須、サードパーティ連携がtelescopeより少ない

## 結論

fzf-luaを採用。理由は → ADR-20260302-004 を参照。
