# Phase 2: 自動ペア（括弧・引用符）選定

## 背景

括弧や引用符を入力するたびに手動で閉じるのは非効率。
VSCode のように自動でペアを閉じる仕組みが必要。

## 候補

| | nvim-autopairs | mini.pairs | ultimate-autopair.nvim |
|---|---|---|---|
| Stars | ~3.3k | ~8.8k (mini.nvim) | ~0.5k |
| treesitter 連携 | あり（文脈判断） | なし | あり |
| nvim-cmp 連携 | 公式サポート | 手動設定が必要 | あり |
| カスタマイズ性 | 高い（ルール追加可） | 低い | 高い |
| 情報量 | 多い | 中程度 | 少ない |

## 比較

### nvim-autopairs
- 強み: nvim-cmp との公式連携、treesitter で文脈判断、定番で情報が多い
- 弱み: mini.pairs より設定がやや多い

### mini.pairs
- 強み: 依存ゼロ、設定が最小限
- 弱み: treesitter 連携なし、nvim-cmp 連携は手動

### ultimate-autopair.nvim
- 強み: 高機能、treesitter 連携あり
- 弱み: 情報が少ない、新しくエコシステムが小さい

## 検証結果

nvim-autopairs を導入。
- `(` `"` `'` `{` `[` 入力時に自動でペアが閉じることを確認
- nvim-cmp で補完確定時にも自動ペアが動作
- treesitter 連携で文字列・コメント内の不要なペア挿入を抑制

## 結論

nvim-autopairs を採用。nvim-cmp との公式連携があり、treesitter で文脈判断もできる。
定番プラグインで情報量が多く、トラブル時に調べやすい。
