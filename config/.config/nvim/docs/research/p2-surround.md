# Phase 2: 囲み文字操作選定

## 背景

引用符や括弧の追加・変更・削除を効率的に行いたい。
手動で両端を編集するのは非効率でミスも起きやすい。

## 候補

| | nvim-surround | mini.surround | vim-surround |
|---|---|---|---|
| Stars | ~3.3k | ~8.8k (mini.nvim) | ~13.5k |
| 言語 | Lua | Lua | Vim script |
| treesitter 連携 | あり | なし | なし |
| 操作体系 | ys / ds / cs（tpope 互換） | sa / sd / sr（独自） | ys / ds / cs |
| ドットリピート | あり | あり | vim-repeat 必要 |

## 比較

### nvim-surround
- 強み: tpope の vim-surround と同じ操作体系を Lua で再実装、treesitter 連携、ドットリピート対応
- 弱み: mini.surround よりやや大きい

### mini.surround
- 強み: mini.nvim エコシステム内、軽量
- 弱み: 操作体系が独自（sa/sd/sr）で vim-surround の知識が活かせない

### vim-surround
- 強み: tpope 作、最も枯れている、情報量最多
- 弱み: Vim script、ドットリピートに vim-repeat が別途必要

## 検証結果

nvim-surround を導入。デフォルト設定（opts = {}）のみで動作。
- `ysiw"` で単語を `"` で囲めることを確認
- `ds"` で囲みを削除、`cs"'` で変更できることを確認

## 結論

nvim-surround を採用。vim-surround と同じ操作体系で情報の互換性が高く、
Lua 実装でドットリピートも標準対応。
