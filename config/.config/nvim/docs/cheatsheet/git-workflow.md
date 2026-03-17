# Git ワークフロー

## Git (`<leader>g`)

| キー | 説明 |
|------|------|
| `<leader>gc` | Git commits |
| `<leader>gs` | Git status |

## Git Hunk (`<leader>h` / gitsigns)

| キー | モード | 説明 |
|------|--------|------|
| `]c` / `[c` | Normal | 次/前の hunk へ移動 |
| `<leader>hs` | Normal/Visual | hunk をステージ |
| `<leader>hr` | Normal/Visual | hunk をリセット |
| `<leader>hS` | Normal | バッファ全体をステージ |
| `<leader>hR` | Normal | バッファ全体をリセット |
| `<leader>hp` | Normal | hunk プレビュー (ポップアップ) |
| `<leader>hi` | Normal | hunk プレビュー (インライン) |
| `<leader>hb` | Normal | 行の blame 表示 |
| `<leader>hd` | Normal | diff this |
| `ih` | Operator/Visual | hunk テキストオブジェクト |

## Git Toggle (`<leader>t`)

| キー | 説明 |
|------|------|
| `<leader>tb` | inline blame トグル |
| `<leader>tw` | word diff トグル |

## CodeDiff (diff viewer)

| コマンド | 説明 |
|----------|------|
| `:CodeDiff` | ファイルエクスプローラ（git status） |
| `:CodeDiff main` | main との差分 |
| `:CodeDiff main...` | PR風diff（merge-base） |
| `:CodeDiff file HEAD` | 現在ファイルをHEADと比較 |
| `:CodeDiff history` | コミット履歴 |

### diff view 内のキー

| キー | 説明 |
|------|------|
| `]c` / `[c` | 次/前の変更へ |
| `]f` / `[f` | 次/前のファイルへ |
| `t` | レイアウト切替 (side-by-side ↔ inline) |
| `do` / `dp` | 変更取得 / 変更送出 |
| `-` | ファイルのステージ切替 |
| `q` | diff を閉じる |
| `g?` | ヘルプ表示 |
