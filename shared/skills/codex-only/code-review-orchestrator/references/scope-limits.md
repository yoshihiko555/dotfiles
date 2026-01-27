# 全体レビューのスコープ制限

## 原則
- 最大 30 ファイルまで
- 入口/境界/中核ロジック/データ層/セキュリティを優先
- 変更履歴が多い/バグ率が高い領域を優先

## フェーズ
1. 地図化: ルート構成・主要エントリ・設定群を把握
2. 高リスク優先: 認証/認可、API境界、DB操作、外部連携
3. サンプル: 残りは代表ファイルのみ

## 選定ルール（例）
- 入口: main/entrypoint, routes, controllers, handlers
- 境界: repositories, adapters, gateways
- 中核: domain/core/usecase/service
- データ: migrations, schema, queries
- 設定: env, deploy, CI/CD, compose

## 超過時の対応
- 30ファイルを超える場合、対象外の理由を明記する
- 優先ディレクトリやファイルパターンをユーザーに確認する
