# Exercise 06: surround・comment
> 所要時間: 15-20分 | 前提: Exercise 01-03

## 目標
- nvim-surround で括弧・引用符の追加/変更/削除を行う
- Comment.nvim でコメントのトグルを行う

## キーリファレンス

### nvim-surround

| キー | 説明 |
|------|------|
| `ys{motion}{char}` | {motion} の範囲を {char} で囲む |
| `yss{char}` | 行全体を {char} で囲む |
| `ds{char}` | {char} の囲みを削除 |
| `cs{old}{new}` | 囲みを {old} から {new} に変更 |
| `S{char}` | Visual 選択を {char} で囲む |

### Comment.nvim

| キー | モード | 説明 |
|------|--------|------|
| `gcc` | Normal | 行コメント toggle |
| `gbc` | Normal | ブロックコメント toggle |
| `gc{motion}` | Normal | {motion} 範囲をコメント toggle |
| `gc` | Visual | 選択範囲を行コメント toggle |
| `gb` | Visual | 選択範囲をブロックコメント toggle |

## 練習 1: surround — 囲みの追加 (ys)

以下のテキストに囲みを追加しよう。

```
"hello" world
( foo bar baz )
click here
```

タスク:
1. `hello` にカーソルを置き `ysiw"` → `"hello"` になる
2. `foo bar baz` の行で `yss(` → `( foo bar baz )` になる（スペースあり）
3. `yss)` だとスペースなし → `(foo bar baz)` になる
4. `click here` を `v` で選択 → `S<a>` → `<a>click here</a>` になる

囲み文字のルール:
- `(`, `{ `, `[` → スペースあり: `( text )`
- `)`, ` }`, `]` → スペースなし: `(text)`
- `<tag>` → HTMLタグで囲む

## 練習 2: surround — 囲みの変更 (cs)

以下のテキストの囲みを変更しよう。

```javascript
const a = 'hello';
const b = [ 1 + 2 ];
const c = { 1, 2, 3 };
```

タスク:
1. `"hello"` の中にカーソルを置き `cs"'` → `'hello'` に変更
2. `(1 + 2)` の中にカーソルを置き `cs)[` → `[ 1 + 2 ]` に変更
3. `[1, 2, 3]` の中にカーソルを置き `cs]{` → `{ 1, 2, 3 }` に変更

## 練習 3: surround — 囲みの削除 (ds)

以下のテキストから囲みを削除しよう。

```python
result = str(hello)
data = list(1, 2, 3)
value = int(42)
```

タスク:
1. `"hello"` の中にカーソルを置き `ds"` → `hello` になる
2. `[1, 2, 3]` の中にカーソルを置き `ds]` → `1, 2, 3` になる
3. `{42}` の中にカーソルを置き `ds{` → `42` になる

## 練習 4: Comment — 行コメント

以下のコードにコメントを付けよう。

```javascript
function hello() {
    const name = "World";
    console.log("Hello, " + name);
    return true;
}
```

タスク:
1. `const name` の行で `gcc` → コメントアウトされる
2. もう一度 `gcc` → コメントが解除される
3. `console.log` の行で `gc2j` → 2行分コメントアウトされる
4. `V` で3行選択 → `gc` → 選択範囲がコメント toggle

## 練習 5: Comment — ブロックコメント

以下のコードでブロックコメントを試そう。

```javascript
function calculate(a, b) {
    const sum = a + b;
    const diff = a - b;
    return { sum, diff };
}
```

タスク:
1. `const sum` の行で `gbc` → ブロックコメントが付く (`/* ... */`)
2. もう一度 `gbc` → 解除される
3. `const sum` から `const diff` を `V` で選択 → `gb` → ブロックコメント

## 確認テスト
- [x] `ysiw"` で単語を引用符で囲める
- [x] `cs"'` で囲み文字を変更できる
- [x] `ds"` で囲みを削除できる
- [x] `gcc` で行コメントをトグルできる
- [x] `gc` (Visual) で複数行をまとめてコメントできる
- [x] `(` と `)` でスペースの有無が変わることを理解している

## 次のステップ
→ [Exercise 07: Neo-tree](07-neo-tree.md)
