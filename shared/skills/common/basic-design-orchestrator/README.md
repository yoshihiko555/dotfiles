# 基本設計オーケストレーター（Skill）

個人開発向けに、基本設計フェーズを「Step-Auto」に沿って半自動化し、最終成果物を **Markdown 1枚**で出力するためのスキルです。

## できること

- 設計対象（UI / API / DB / Batch / NFR / 複合）を判定し、必要な章テンプレを選んで **1枚Markdown** に統合
- 不足情報が多い場合は推測で埋めず、**最大5件の確認質問**を出して停止
- 図は Mermaid 前提（必要最小限）

## 構成

- スキル本体: `basic-design-orchestrator/SKILL.md`
- 擬似モジュール（テンプレ/チェック/質問）: `basic-design-orchestrator/references/`
  - Step-Auto: `basic-design-orchestrator/references/step-auto.md`
  - ルーティング: `basic-design-orchestrator/references/routing.md`
  - 1枚骨格: `basic-design-orchestrator/references/template-base.md`
  - UI/API/DB/Batch/NFR: `basic-design-orchestrator/references/ui.md` など
  - Mermaid図: `basic-design-orchestrator/references/diagrams.md`
  - 最終ゲート: `basic-design-orchestrator/references/final-gate.md`
  - 質問バンク: `basic-design-orchestrator/references/question-bank.md`

## 使い方（基本）

### 1) スキルを呼ぶ

依頼文に **基本設計** を含めて、`basic-design-orchestrator` が使われる前提で指示します（例: 「基本設計を作って」）。

### 2) 設計対象を明示する（推奨）

設計対象を明示すると、ルーティングが安定します。

- UI: 画面仕様、項目、遷移、エラー
- API: 一覧→各API詳細（認可/冪等/エラー/タイムアウト）
- DB: 一覧→各テーブル詳細（制約/インデックス）
- Batch: 一覧→各ジョブ詳細（再実行/監視）
- NFR: 性能/可用性/運用/セキュリティ

### 3) 不足情報があれば質問に答える

スキルは推測で埋めず、最大5件の確認質問で停止します。回答後、同じスレッドで続けて依頼してください。

## 依頼例（コピペ用）

### UI（単一画面）

```text
画面基本設計をMarkdown 1枚で作ってください。
画面名: ユーザー登録
目的: 新規ユーザーを登録する
入力項目: email（必須）, password（必須, 8文字以上）, 利用規約同意（必須）
遷移: 登録成功→完了画面、失敗→同画面でエラー表示
```

### API（一覧→個別）

```text
API設計をMarkdown 1枚で作ってください（一覧→各API詳細）。
対象API:
- POST /v1/users: ユーザー作成
- GET /v1/users/{id}: ユーザー取得
認証: Bearer token
エラー規約: 既存があればそれに合わせる（なければ提案して）
```

### DB（一覧→個別）

```text
DB設計をMarkdown 1枚で作ってください（一覧→各テーブル詳細）。
主要エンティティ: users, user_profiles
論理削除: あり
PII: email は秘匿扱い（ログはマスキング）
```

## テンプレの調整（個人開発向けの育て方）

- 列追加や見出し名の統一などは、まず `basic-design-orchestrator/references/*.md` を編集して反映します
- 運用して「毎回重い」領域が出たら、将来的に `bd-api` などの分割スキルへ切り出すのが安全です

