# Exercise 08: FzfLua 検索ワークフロー
> 所要時間: 15-20分 | 前提: Exercise 01-03

## 目標
- FzfLua の各検索モードを使い分ける
- 検索結果を分割ウィンドウや Quickfix に送る
- 複数選択で一括操作する

## キーリファレンス

### 検索の起動

| キー | 説明 |
|------|------|
| `<leader>ff` | ファイル検索 |
| `<leader>fg` | Grep 検索 (ファイル内容) |
| `<leader>fb` | バッファ検索 |
| `<leader>fh` | Help 検索 |
| `<leader>fr` | 最近のファイル |
| `<leader>fd` | Diagnostics |
| `<leader>fs` | ドキュメントシンボル |
| `<leader>fw` | ワークスペースシンボル |

### 検索ウィンドウ内操作

| キー | 説明 |
|------|------|
| `Enter` | 選択を開く |
| `Ctrl+v` | 垂直分割で開く |
| `Ctrl+x` | 水平分割で開く |
| `Ctrl+t` | 新しいタブで開く |
| `Ctrl+j` / `Ctrl+k` | 結果リストを上下移動 |
| `Ctrl+d` / `Ctrl+u` | プレビューをスクロール |
| `Ctrl+q` | 結果を Quickfix に送る |
| `Tab` | 複数選択 toggle |
| `Ctrl+a` | すべて選択 |
| `Esc` | 検索を閉じる |

## 練習 1: ファイル検索

1. `<leader>ff` でファイル検索を起動
2. `keymaps` と入力 → ファイル名で絞り込まれる
3. `Ctrl+j`/`Ctrl+k` で結果を移動
4. `Enter` で開く
5. 再度 `<leader>ff` → 別のファイルを `Ctrl+v` で垂直分割で開く

## 練習 2: Grep 検索

1. `<leader>fg` で Grep 検索を起動
2. `vim.keymap` と入力 → ファイル内容から検索
3. 結果を `Ctrl+j`/`Ctrl+k` で移動しながら右のプレビューで確認
4. `Ctrl+d`/`Ctrl+u` でプレビューをスクロール
5. `Enter` で選択した結果を開く

## 練習 3: バッファ検索

1. 複数のファイルを開いた状態にする（`<leader>ff` で2-3個開く）
2. `<leader>fb` でバッファ検索を起動
3. ファイル名を入力して素早く切り替え

## 練習 4: Quickfix 連携

1. `<leader>fg` で Grep 検索を起動
2. `require` と入力（多くの結果が出るはず）
3. `Ctrl+q` で全結果を Quickfix リストに送る
4. `]q` / `[q` で Quickfix を順に移動
5. `<leader>xq` で Quickfix ウィンドウを開く
6. `<leader>xc` で Quickfix ウィンドウを閉じる

## 練習 5: 複数選択

1. `<leader>fg` で Grep 検索を起動
2. 適当なキーワードで検索
3. `Tab` で個別に選択/解除 → 複数の結果にチェックを付ける
4. `Enter` で選択した複数ファイルを開く
5. 再度検索 → `Ctrl+a` で全選択 → `Ctrl+q` で Quickfix に送る

## 練習 6: 効率的な検索ワークフロー

以下のシナリオを実践しよう:

**シナリオ: 関数の定義と使用箇所を探す**
1. `<leader>fg` で関数名を Grep 検索
2. 定義箇所を `Enter` で開く
3. `<leader>fg` で再度同じ関数名を検索
4. 使用箇所を `Ctrl+v` で分割表示 → 定義と使用箇所を並べて確認

**シナリオ: 最近のファイルに素早く戻る**
1. `<leader>fr` で最近のファイル一覧
2. 数文字入力で絞り込み → `Enter` で開く

## 確認テスト
- [x] `<leader>ff` でファイルを素早く見つけて開ける
- [x] `<leader>fg` でファイル内容を検索できる
- [x] `Ctrl+v`/`Ctrl+x` で分割ウィンドウにファイルを開ける
- [x] `Ctrl+q` で検索結果を Quickfix に送れる
- [x] `Tab` で複数選択して一括操作できる

## 次のステップ
→ [Exercise 09: LSP ワークフロー](09-lsp-workflow.md)
