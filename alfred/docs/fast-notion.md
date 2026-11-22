# Notion にタスクを追加する（`fna`）

Notion のタスクDB（`T A S K`）へタスクを素早く追加するワークフロー。

## 使い方

1. Alfred で `fna タスク名` と入力
2. 下にプロジェクト候補が並ぶので、紐づけたいものを選ぶ（`プロジェクトなしで追加` も先頭にある）
3. `fna タスク名 @cli` のように `@` 以降を書くとプロジェクトを絞り込める
   （プロジェクト名・カテゴリ・管理値が対象）

## 動作

- タスクは `template_id` 経由で「タスクテンプレート」が適用される。
  アイコン（`checkmark-square`）・ステータス=`待ち`・GTD種別=`INBOX`・優先度=`低` が入る
- **テンプレートの適用は非同期。** 作成レスポンスにはまだ反映されていないため、
  レスポンスだけを見て「効いていない」と判断しないこと（2026-08-30 実測）
- プロジェクト一覧は 10 分キャッシュする（`alfred_workflow_cache`）。
  Script Filter は1打鍵ごとに走るため、キャッシュが無いと毎回 API を叩くことになる
- 取得に失敗した場合は期限切れキャッシュで代替する

## Notion 側の前提

- Integration に **タスクDB（`T A S K`）と PROJECT DB の両方**を共有しておく。
  PROJECT DB が未共有だと候補が取得できないうえ、TASK DB の
  `プロジェクト名` リレーションプロパティ自体が API から見えなくなる

## 秘匿情報の扱い

当リポジトリは public なので、Notion Integration Token は info.plist に置かない。
Alfred の Workflow Configuration（ワークフロー右上の `[x]` ボタン）で設定する。

| 値 | 置き場所 |
|---|---|
| `TOKEN` | Alfred の Configure Workflow（`prefs.plist` に保存。`.gitignore` 済み） |
| `DATABASE_ID` / `PROJECT_DB_ID` / `TEMPLATE_ID` | `info.plist` の `variables`（ID のみで秘匿情報ではない） |

初回セットアップ時、または `prefs.plist` を失った場合は Configure Workflow で
トークンを再入力する。未設定のまま実行するとエラーメッセージが出る。

[Alfred のワークフロー一覧](../README.md)
