# Phase 2: 補完エンジン選定

## 背景

Neovim 組み込み LSP は動作しているが、補完は `<C-x><C-o>` の手動トリガーのみ。
入力中に自動で補完候補をポップアップ表示する仕組みが必要。

## 候補

| | nvim-cmp | coq_nvim | mini.completion | blink.cmp |
|---|---|---|---|---|
| Stars | ~8.5k | ~3.5k | ~8.8k (mini.nvim) | ~4.2k |
| 言語 | Lua | Python + Lua | Lua | Lua + Rust |
| 外部依存 | なし | Python3 必須 | なし | なし |
| ソースプラグイン | 豊富（LSP, buffer, path, snippet 等） | 組み込み | 最小限 | 組み込み |
| スニペット連携 | LuaSnip / vsnip 等選択可 | 組み込み | なし | 組み込み |
| カスタマイズ性 | 高い | 中程度 | 低い | 高い |
| エコシステム | 最大 | 小さい | mini.nvim 内 | 成長中 |

## 比較

### nvim-cmp
- 強み: デファクトスタンダード、ソースプラグインが豊富、情報量が最も多い
- 弱み: 設定がやや冗長、ソースごとに依存プラグインが増える

### blink.cmp
- 強み: Rust 製で高速、設定がシンプル、組み込みソースが充実
- 弱み: 比較的新しく情報が少ない、nvim-cmp のソースプラグインと互換性なし

### coq_nvim
- 強み: 高速、スニペット組み込み
- 弱み: Python3 必須、エコシステムが小さい

### mini.completion
- 強み: 依存ゼロ、軽量
- 弱み: カスタマイズ性が低い、スニペット非対応

## 検証結果

nvim-cmp + cmp-nvim-lsp + LuaSnip + friendly-snippets を導入。
- Go ファイルで `fmt.` 入力時に LSP 補完候補がポップアップ表示されることを確認
- Tab / S-Tab で候補選択、CR で確定、C-Space で手動トリガーが動作
- コマンドライン（`:` `/`）の補完も動作

## 結論

nvim-cmp を採用。デファクトスタンダードで情報量が多く、トラブル時に調べやすい。
スニペットエンジンは LuaSnip + friendly-snippets の定番構成を選択。
