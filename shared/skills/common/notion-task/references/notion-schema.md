# Notion タスクDB スキーマ参照

`notion-task` スキルが使う Notion 側の ID とプロパティ定義。
Notion 側で DB 構成を変えたら、このファイルも更新すること。

（最終確認: 2026-07-28）

## ID 一覧

| 対象 | ID / URL |
|---|---|
| タスクDB（データソース） | `collection://1316d81a-ac52-81be-b589-000baec0b7a6` |
| タスクDB（データベースページ） | https://app.notion.com/p/1316d81aac5281d0bb64ed21cae0a9f0 |
| **タスクテンプレート** | `1316d81a-ac52-81fe-a86a-fce74cbd7667` |
| PROJECT DB（データソース） | `collection://1316d81a-ac52-81d7-9f80-000be29f2f01` |

タスクテンプレートはタスクDBの `default_page_template` にも設定されているが、
MCP の `create-pages` は既定テンプレートを自動適用しないため、
**`template_id` に明示的に渡す必要がある**。

## タスクテンプレートの中身

| 項目 | 値 |
|---|---|
| アイコン | `icons/checkmark-square_lightgray`（絵文字ではなく Notion 組み込みアイコン） |
| 本文 | 空 |
| ステータス | `待ち` |
| GTD種別 | `INBOX` |
| 優先度 | `低` |

アイコンは絵文字ではないため、`create-pages` の `icon` 引数（絵文字 / カスタム絵文字名 /
外部画像URL のみ対応）では正しく再現できない。`template_id` 経由で継承させるのが唯一の手段。
だから `icon` を指定してはいけない。

### 本文は同時に渡せない（実測済み・2026-07-28）

`create-pages` で `template_id` と `content` を同時に指定すると 400 になる。

```
validation_error: Cannot specify both 'content' and 'template_id'.
The template will provide the page content.
```

タスクテンプレートの本文は空なので、本文は作成後に `update-page`
（`command: "insert_content"`, `position: {"type":"end"}`）で追記する。
この2段階でアイコン・既定プロパティ・本文がすべて意図どおりになることを実ページで確認済み。

## タスクDB（`T A S K`）プロパティ

| プロパティ | 型 | 値 / 備考 |
|---|---|---|
| `タスク名` | title | 必須 |
| `ステータス` | status | `待ち` / `保留` / `確認中` / `進行中` / `完了` / `中断` |
| `GTD種別` | status | `INBOX` / `次に取るべき行動` / `いつかやる・たぶんやる` / `待ち` / `ゴミ箱` |
| `優先度` | select | `低` / `中` / `高` |
| `期限日` | date | SQL では `date:期限日:start` |
| `開始日` | date | SQL では `date:開始日:start` |
| `プロジェクト名` | relation → PROJECT DB | ページURLの JSON 配列 |
| `親アイテム` | relation → 自DB（上限1） | ページURLの JSON 文字列 |
| `サブアイテム` | relation → 自DB | 親側から見た子。子の `親アイテム` を設定すれば自動で埋まる |
| `K E Y - R E S U L T` | relation | スキルからは設定しない |
| `ポモロード_見込` / `ポモロード_実績` | number | スキルからは設定しない |
| `サブタスク進捗率` / `作業時間` / `プロジェクトカテゴリ` / `プロジェクトステータス` / `プロジェクト識別ID` / `四半期` | rollup / formula | 読み取り専用 |
| `■` / `▶` | button | 操作対象外 |

### 重複チェック用のクエリ例

```sql
SELECT "タスク名", url FROM "collection://1316d81a-ac52-81be-b589-000baec0b7a6"
WHERE "ステータス" NOT IN ('完了', '中断')
  AND "タスク名" LIKE ?
```

## PROJECT DB（`P R O J E C T`）プロパティ

プロジェクト候補の検索に使う。タイトルは `プロジェクト名`。

| プロパティ | 型 | 値 / 備考 |
|---|---|---|
| `プロジェクト名` | title | 検索対象 |
| `ステータス` | status | `保留` / `待ち` / `進行中` / `完了` / `中断` |
| `カテゴリ` | select | `Nat` / `Ci` / `Ci3` / `GW` / `Anvil` / `Jedeite` / `MMI` / `SPIC` / `Event System` / `Personal` |
| `管理タイプ` | select | `期` / `バージョン` / `年` / `フェーズ` |
| `対応期間` | date | |

### 候補検索のクエリ例

完了・中断したプロジェクトを候補に出しても意味がないので除外する。

```sql
SELECT "プロジェクト名", "カテゴリ", url
FROM "collection://1316d81a-ac52-81d7-9f80-000be29f2f01"
WHERE "ステータス" NOT IN ('完了', '中断')
```

## 関連する既存の運用

Notion ワークスペース側に、同じテンプレート運用を前提にした
**「議事録からタスク化」スキル**（https://app.notion.com/p/4e0510ee97bf4ef1be99d33e3d0f24bf）
が既にある。対象が議事録ページか会話かの違いで、テンプレート適用・確認必須・
期限を勝手に設定しないという方針は共通。挙動を変える際は両方を揃えること。
