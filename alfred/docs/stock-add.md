# Notion で在庫を補充する（`stock`）

Notion の欲しいものリスト（`W I S H - L I S T`）から、優先度=高 の在庫を補充するワークフロー。

## 使い方

1. Alfred で `stock` と入力すると、優先度=高 の商品が一覧表示される
2. 補充した商品を選択すると在庫が加算される
3. `stock 洗濯` のように商品名・カテゴリで絞り込める

## 対象

`購入状況=再購入` かつ `発注点≠0` かつ `優先度=高`。
Notion のビュー「在庫管理（取扱中）」に `優先度=高` を足した条件と一致する
（`発注点` 未設定の行も `does_not_equal 0` に該当し、ビューと同じ結果になる。2026-09-15 実測）。

## 動作

Notion の `在庫追加` ボタン（button プロパティ）と同じ処理を Notion API で再現する。

1. `S T O C K - R E P L E N I S H` に `{商品名, 購入日=今日}` を作成
2. `W I S H - L I S T` を更新（`実在庫 += 入数` / `優先度=低` / `_在庫履歴` に追記）

> **button プロパティは API から押すことも読むこともできない。**
> このため本家ボタンの内容を再現している。ボタン本体は 1. の部分を
> GAS の Webhook（`stockRelation`）へ投げているが、当ワークフローは
> Webhook を経由せず Notion API へ直接書き込む。
> 本家の実装は `yoshihiko555/google-apps-scripts` の
> `apps/notion/Db/inventory.js` にある。

## 壊れやすい点

- `_在庫履歴` は**一方向リレーション**なので、商品ページ側を PATCH するしかない。
  PATCH はリレーション配列を**置換**するため、既存 ID を読んで追記して書き戻している
- ページ取得のリレーションは 25 件で打ち切られる（`has_more`）。
  打ち切られたまま書き戻すと履歴が消えるので、その場合は
  `GET /pages/{id}/properties/{prop_id}` でページングして全件取得する
- 補充後は `優先度=低` になり一覧から外れるため、実行時にキャッシュを削除する
- 一覧は 10 分キャッシュする（`alfred_workflow_cache`）

## Notion 側の前提

- Integration に **`W I S H - L I S T` と `S T O C K - R E P L E N I S H` の両方**を
  共有しておく。在庫履歴DB が未共有だと履歴ページを作れないうえ、
  `_在庫履歴` リレーションが**空で返る**（＝書き戻しで既存履歴が消える）。
  破壊的な更新に入る前に在庫履歴DB へアクセスできるか検査して中断している

## 秘匿情報の扱い

| 値 | 置き場所 |
|---|---|
| `TOKEN` | Alfred の Configure Workflow（`prefs.plist` に保存。`.gitignore` 済み） |
| `WISHLIST_DB_ID` / `STOCK_DB_ID` | `info.plist` の `variables`（ID のみで秘匿情報ではない） |

[Alfred のワークフロー一覧](../README.md)
