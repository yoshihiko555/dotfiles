# Exercise 02: テキストオブジェクト
> 所要時間: 15-20分 | 前提: Exercise 01

## 目標
- `i` (inner) と `a` (around) の違いを体感する
- `w`, `"`, `(`, `{`, `t` などの対象を使いこなす
- オペレータ + テキストオブジェクトの組み合わせに慣れる

## キーリファレンス

| キー | 説明 |
|------|------|
| `diw` | 単語を削除 (空白除く) |
| `daw` | 単語を削除 (空白含む) |
| `ci"` | `"..."` の中身を変更 |
| `ca"` | `"..."` 全体を変更 |
| `di(` | `(...)` の中身を削除 |
| `da(` | `(...)` 全体を削除 |
| `di{` | `{...}` の中身を削除 |
| `dit` | HTMLタグの中身を削除 |
| `yip` | 段落をコピー |

## 練習 1: inner vs around (単語)

以下の文の `unnecessary` を削除しよう。

```
This is an unnecessary word in the sentence.
This is an unnecessary word in the sentence.
```

タスク:
1. 1行目: `unnecessary` にカーソルを置き `diw` → 単語だけ消える（空白が残る）
2. 2行目: `unnecessary` にカーソルを置き `daw` → 単語と前の空白も消える

違いを確認: `diw` は空白を残し、`daw` はきれいに削除する。

## 練習 2: 引用符の中身を操作

以下の各行で指示された操作を行おう。

```javascript
const name = "Alice";
const greeting = "Hello, World!";
const message = 'This is a test';
```

タスク:
1. 1行目: `"Alice"` の中にカーソルを置き `ci"` → `Bob` と入力 → `Esc`
2. 2行目: `"Hello, World!"` の中にカーソルを置き `di"` → 中身だけ消える
3. 3行目: `'This is a test'` の中にカーソルを置き `ca'` → 引用符ごと消える

## 練習 3: 括弧の中身を操作

以下のコードで括弧内を操作しよう。

```python
result = calculate(price, quantity, tax)
data = {"name": "Alice", "age": 30}
items = [apple, banana, cherry]
```

タスク:
1. 1行目: `(price, quantity, tax)` の中にカーソルを置き `ci(` → `total` と入力 → `Esc`
2. 2行目: `{...}` の中にカーソルを置き `di{` → 中身だけ消える
3. 3行目: `[...]` の中にカーソルを置き `da[` → 括弧ごと消える

## 練習 4: HTMLタグ

以下のHTMLでタグ内を操作しよう。

```html
<div>
  <p>This paragraph should be changed.</p>
  <span>Remove this text</span>
  <a href="https://example.com">Click here</a>
</div>
```

タスク:
1. `<p>` タグの中にカーソルを置き `cit` → `新しい段落` と入力 → `Esc`
2. `<span>` タグの中にカーソルを置き `dit` → 中身だけ消える
3. `href="..."` の `"` の中にカーソルを置き `ci"` → URL を変更

## 練習 5: 段落操作

以下の2つの段落を操作しよう。

```
最初の段落です。
複数行にわたっています。
ここまでが1段落目。

2つ目の段落です。
これも複数行。
ここまでが2段落目。
```

タスク:
1. 1段落目の任意の行にカーソルを置き `yip` → 段落をコピー
2. 2段落目の後の空行で `p` → コピーした段落がペーストされる
3. `dap` で段落ごと削除（前後の空行含む）

## 確認テスト
- [ ] `diw` と `daw` の違いを説明できる
- [ ] `ci"` で引用符の中身を素早く変更できる
- [ ] `di(`, `di{`, `di[` で各種括弧内を操作できる
- [ ] `dit` でHTMLタグ内を操作できる
- [ ] `ip`/`ap` で段落を扱える

## 次のステップ
→ [Exercise 03: Visual モード](03-visual-mode.md)
