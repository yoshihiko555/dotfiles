# Exercise 05: 検索・置換
> 所要時間: 15-20分 | 前提: Exercise 01-03

## 目標
- `/`, `?`, `n`, `N` で素早く検索・移動する
- `*`, `#` でカーソル下の単語を検索する
- `:s` と `:%s` で置換を使いこなす

## キーリファレンス

| キー | 説明 |
|------|------|
| `/{pattern}` | 前方検索 |
| `?{pattern}` | 後方検索 |
| `n` / `N` | 次/前の検索結果 |
| `*` | カーソル下の単語を前方検索 |
| `#` | カーソル下の単語を後方検索 |
| `Esc` | 検索ハイライト解除 (カスタム) |
| `:{範囲}s/old/new/g` | 置換 |
| `:%s/old/new/g` | 全行置換 |
| `:%s/old/new/gc` | 確認付き全行置換 |

## 練習 1: 基本検索

以下のテキストで `error` を検索しよう。

```
Line 1: This is normal text.
Line 2: An error occurred here.
Line 3: Processing continues.
Line 4: Another error was found.
Line 5: The error handling is important.
Line 6: All tasks completed.
Line 7: No error detected.
```

タスク:
1. `/error` と入力して `Enter` → 最初の `error` にジャンプ
2. `n` で次の `error` に移動 → 繰り返す
3. `N` で前の `error` に戻る
4. `Esc` でハイライトを消す
5. `?error` で後方検索を試す

## 練習 2: * と # でカーソル下検索

以下のコードで変数 `count` の使用箇所を探そう。

```javascript
let count = 0;
function increment() {
    count = count + 1;
    console.log("Current count:", count);
    if (count > 10) {
        resetCount();
    }
}
function resetCount() {
    count = 0;
}
```

タスク:
1. 最初の `count` にカーソルを置き `*` → 次の `count` にジャンプ
2. `n` で次々と移動して全ての `count` を確認
3. `#` で逆方向に移動
4. `resetCount` にカーソルを置き `*` → `count` ではなく `resetCount` だけがマッチすることを確認

## 練習 3: 行内置換 (:s)

以下の1行を編集しよう。

```
foo bar foo baz foo qux foo
```

タスク:
1. その行にカーソルを置き `:s/foo/FOO/` → 最初の `foo` だけ置換される
2. `u` で戻す
3. `:s/foo/FOO/g` → 行内の全ての `foo` が置換される
4. `u` で戻す

## 練習 4: 全行置換 (:%s)

以下のコードの `newName` を `newName` に全て置換しよう。

```python
def oldName():
    print("newName called")
    return oldName

class MyClass:
    def __init__(self):
        self.oldName = oldName()
```

タスク:
1. `:%s/oldName/newName/g` → 全ての `oldName` が一括置換される
2. `u` で戻す
3. `:%s/oldName/newName/gc` → 確認付き置換（`y`/`n` で個別に選択）

確認付き置換のキー:
- `y` → この箇所を置換
- `n` → スキップ
- `a` → 残り全て置換
- `q` → 終了

## 練習 5: 範囲指定置換

以下のテキストの3行目から5行目だけを置換しよう。

```
Line 1: apple is good
Line 2: apple is great
Line 3: orange is nice
Line 4: orange is fine
Line 5: orange is cool
Line 6: apple is best
```

タスク:
1. `:3,5s/apple/orange/g` → 3〜5行目の `apple` だけ置換される
2. `u` で戻す
3. 3行目で `V` → 5行目まで選択 → `:` を押すと `:'<,'>` が自動入力される
4. `:'<,'>s/apple/orange/g` → Visual 選択範囲の `apple` が置換される

## 確認テスト
- [x] `/pattern` で検索して `n`/`N` で移動できる
- [x] `*` でカーソル下の単語を素早く検索できる
- [x] `:s/old/new/g` で行内置換ができる
- [x] `:%s/old/new/gc` で確認付き全行置換ができる
- [x] 範囲指定 (`:3,5s/...`) や Visual 選択からの置換ができる

## 次のステップ
→ [Exercise 06: surround・comment](06-surround-comment.md)
