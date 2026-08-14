# Exercise 10: Git ワークフロー
> 所要時間: 15-20分 | 前提: Exercise 08 (FzfLua)

## 目標
- gitsigns で hunk 単位のステージ/リセットを行う
- inline blame と word diff を活用する
- CodeDiff でコミット間の差分を確認する

## キーリファレンス

### gitsigns (hunk 操作)

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

### Git Toggle

| キー | 説明 |
|------|------|
| `<leader>tb` | inline blame トグル |
| `<leader>tw` | word diff トグル |

### FzfLua Git

| キー | 説明 |
|------|------|
| `<leader>gc` | Git commits |
| `<leader>gs` | Git status |

### CodeDiff

| コマンド | 説明 |
|----------|------|
| `:CodeDiff` | git status の diff |
| `:CodeDiff main` | main との差分 |
| `:CodeDiff main...` | PR風diff (merge-base) |
| `:CodeDiff history` | コミット履歴 |

## 練習 1: hunk ナビゲーション

Git リポジトリ内のファイルを編集して変更を作ろう。

1. 任意のファイルを開き、数行編集して保存 (`:w`)
2. 左端に変更マーカー（緑の `+` や青の `~`）が表示されることを確認
3. `]c` で次の hunk にジャンプ
4. `[c` で前の hunk にジャンプ
5. `<leader>hp` で hunk のプレビュー（変更前の内容がポップアップ表示）
6. `<leader>hi` でインラインプレビュー

## 練習 2: hunk のステージとリセット

1. ファイルに複数箇所の変更を加える（3箇所以上）
2. 最初の hunk に移動して `<leader>hs` → その hunk だけステージされる
3. 次の hunk に移動して `<leader>hr` → その hunk だけリセット（変更が消える）
4. `<leader>hS` でバッファ全体をステージ

hunk テキストオブジェクトの活用:
1. 変更がある行で `vih` → hunk が Visual 選択される
2. `dih` → hunk を削除

## 練習 3: blame と word diff

1. 任意のファイルで `<leader>hb` → カーソル行の blame（コミット情報）がポップアップ
2. `<leader>tb` → 全行に inline blame が表示される（トグル）
3. `<leader>tw` → word diff モードに切り替え（行内の変更箇所がハイライト）
4. もう一度 `<leader>tw` で解除

## 練習 4: FzfLua で Git 操作

1. `<leader>gs` で Git status → 変更ファイル一覧が表示される
2. ファイルを選択して差分を確認
3. `<leader>gc` で Git commits → コミット履歴を検索・確認

## 練習 5: CodeDiff

1. `:CodeDiff` → git status ベースの diff ビューが開く
2. `]c` / `[c` で変更箇所間を移動
3. `]f` / `[f` でファイル間を移動
4. `t` でレイアウト切替 (side-by-side ↔ inline)
5. `q` で diff を閉じる

ブランチ比較:
1. `:CodeDiff main` → main ブランチとの差分
2. `:CodeDiff main...` → PR 風 diff (merge-base から)
3. `:CodeDiff history` → コミット履歴ブラウザ

## 練習 6: 実践ワークフロー

以下のシナリオを通しで行おう:

1. ファイルを編集して複数の変更を作る
2. `]c` / `[c` で変更箇所を確認
3. `<leader>hp` で各 hunk の内容を確認
4. 必要な hunk だけ `<leader>hs` でステージ
5. 不要な hunk は `<leader>hr` でリセット
6. `:CodeDiff` で最終確認
7. ターミナルで `git commit`

## 確認テスト
- [x] `]c`/`[c` で hunk 間を移動できる
- [x] `<leader>hs` で hunk 単位でステージできる
- [x] `<leader>hr` で hunk をリセットできる
- [x] `<leader>hp` で hunk のプレビューを表示できる
- [x] `<leader>tb` で inline blame をトグルできる
- [x] `:CodeDiff` で diff ビューを開いて操作できる
- [x] `ih` テキストオブジェクトで hunk を選択できる

## まとめ
全10回の Exercise お疲れさまでした。[チートシート](../cheatsheet/README.md)を手元に置きながら日常的に使うことで定着します。
