# Exercise 09: LSP ワークフロー
> 所要時間: 15-20分 | 前提: Exercise 08 (FzfLua)

## 目標
- LSP のジャンプ機能 (定義/参照/実装) を活用する
- Diagnostics を効率的に確認・移動する
- リネームとコードアクションを使う

## キーリファレンス

| キー | 説明 |
|------|------|
| `<leader>lf` | 定義・参照・実装などをFzfLuaでまとめて表示 |
| `<leader>ld` | 定義を表示 |
| `<leader>lD` | 宣言を表示 |
| `<leader>lr` | 参照箇所をFzfLuaで一覧表示 |
| `<leader>li` | 実装を表示 |
| `<leader>lt` | 型定義を表示 |
| `<leader>lh` | 型情報・ドキュメントを表示 |
| `<leader>lp` | 関数の引数情報を表示 |
| `<leader>ln` | リネーム |
| `<leader>la` | コードアクション |
| `<leader>le` | 行の Diagnostics |
| `<leader>lk` / `<leader>lj` | 前/次の Diagnostic |
| `<leader>fd` | Diagnostics (FzfLua) |
| `<leader>ls` | ドキュメントシンボル |
| `<leader>lS` | ワークスペースシンボル |
| `Ctrl+o` | ジャンプ前の位置に戻る |

**対応 LSP**: gopls, pyright, ts_ls, lua_ls

## 練習 1: 定義ジャンプと戻る

LSP 対応のプロジェクト (Go/Python/TypeScript) で実践しよう。

1. 任意の関数呼び出しにカーソルを置く
2. `<leader>ld` で定義一覧を表示し、定義元へジャンプ
3. `Ctrl+o` で元の位置に戻る
4. `<leader>lD` で宣言一覧を表示（言語による）

ポイント: `<leader>ld` → `Ctrl+o` のループが最も頻繁に使うパターン。

## 練習 2: 参照一覧と実装

1. 関数やメソッドの定義にカーソルを置く
2. `<leader>lr` で参照一覧を表示（候補が1件でもFzfLuaで表示される）
3. リストから選択して `Enter` で参照箇所にジャンプ
4. `Ctrl+o` で元の位置に戻る（一覧を閉じるだけなら `Esc`）
5. インターフェースのメソッドで `<leader>li` → 実装一覧を表示

## 練習 3: ホバー情報

1. 関数名にカーソルを置いて `<leader>lh` → 型情報やドキュメントが表示される
2. もう一度 `<leader>lh` → ホバーウィンドウにフォーカスが移る（スクロール可能）
3. `q` でホバーを閉じる

`<leader>lf` では、同じシンボルの定義・参照・実装をプレビュー付きの一覧で
まとめて確認できる。`<leader>lh` の型情報・ドキュメント表示と使い分けよう。

## 練習 4: Diagnostics ナビゲーション

1. エラーや警告のあるファイルを開く（意図的にエラーを含むコードを書いてもよい）
2. `<leader>lj` で次の Diagnostic にジャンプ
3. `<leader>lk` で前の Diagnostic にジャンプ
4. `<leader>le` で現在行の Diagnostic 詳細を表示
5. `<leader>fd` で全 Diagnostics を FzfLua で一覧表示

## 練習 5: リネーム

1. リネームしたい変数や関数にカーソルを置く
2. `<leader>ln` → 新しい名前を入力 → `Enter`
3. 全ての参照箇所が自動で更新されることを確認
4. `u` で Undo → 全ての変更が一度に戻る

## 練習 6: コードアクション

1. エラーや警告がある行にカーソルを置く
2. `<leader>la` でコードアクション一覧を表示
3. 利用可能なアクション（import の自動追加、型の修正など）を選択

よくあるコードアクション:
- 不足している import の追加
- 未使用変数の削除
- インターフェースの自動実装

## 練習 7: シンボル検索

1. `<leader>ls` でドキュメント内のシンボル一覧を表示
2. 関数名やクラス名を入力して絞り込み
3. `<leader>lS` でワークスペース全体のシンボルを検索

## 確認テスト
- [ ] `<leader>ld` で定義にジャンプし `Ctrl+o` で戻れる
- [ ] `<leader>lr` で参照一覧を表示しジャンプできる
- [ ] `<leader>lh` で型情報やドキュメントを確認できる
- [ ] `<leader>lj` / `<leader>lk` で Diagnostic 間を素早く移動できる
- [ ] `<leader>ln` でプロジェクト全体のリネームができる
- [ ] `<leader>la` でコードアクションを実行できる

## 次のステップ
→ [Exercise 10: Git ワークフロー](10-git-workflow.md)
