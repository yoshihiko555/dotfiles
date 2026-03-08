# Phase 2: コメントトグル選定

## 背景

コードのコメント化・解除を手早く行いたい。
VSCode の `Cmd+/` に相当する操作を Neovim で実現する。

## 候補

| | Comment.nvim | mini.comment | vim-commentary |
|---|---|---|---|
| Stars | ~4.1k | ~8.8k (mini.nvim) | ~5.8k |
| 言語 | Lua | Lua | Vim script |
| treesitter 連携 | あり（言語ごとのコメント記号を自動判定） | あり | なし |
| ブロックコメント | あり（gbc） | なし | なし |
| 操作体系 | gcc / gc + モーション | gcc / gc + モーション | gcc / gc + モーション |

## 比較

### Comment.nvim
- 強み: ブロックコメント対応、treesitter 連携、情報量が多い
- 弱み: mini.comment より依存が1つ多い（実質ゼロ設定で動くが）

### mini.comment
- 強み: mini.nvim エコシステム内、依存ゼロ
- 弱み: ブロックコメント非対応

### vim-commentary
- 強み: tpope 作、枯れている
- 弱み: Vim script、treesitter 連携なし

## 検証結果

Comment.nvim を導入。デフォルト設定（opts = {}）のみで動作。
- `gcc` で行コメントトグルを確認
- ビジュアル選択 + `gc` で範囲コメントを確認
- Go / Lua / TypeScript で正しいコメント記号が使われることを確認

## 結論

Comment.nvim を採用。ブロックコメント対応があり、treesitter 連携で多言語に対応。
デフォルト設定のみで実用的。
