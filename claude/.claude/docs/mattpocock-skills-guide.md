# mattpocock/skills 使い分けガイド

[mattpocock/skills](https://github.com/mattpocock/skills) プラグイン（engineering + productivity）の各スキルの役割と使い分けメモ。

## 全体像

「アイデア → 仕様 → チケット → 実装 → レビュー」の開発ライフサイクル全体をカバーするスキル集。

- **ユーザー起動専用**: `/mattpocock-skills:<name>` と明示的に打ったときだけ動く（ワークフローの起点になる大物系）
- **モデル起動可**: 会話の文脈から Claude が自動で呼び出せる（日常作業の支援系）

## 典型的なワークフロー

1. アイデア段階: `/grill-with-docs` で計画を叩く（用語集・ADR が育つ）
2. `/to-spec` で仕様化 → `/to-tickets` でチケット分解（巨大案件なら `/wayfinder`）
3. `/triage` でチケットをエージェント実行可能な状態に整備
4. `/implement` が `tdd` → `code-review` を駆動して実装・レビュー
5. 詰まったら `diagnosing-bugs` / `prototype` / `research` を随時投入

## 計画・仕様化フェーズ

| スキル | 起動 | 役割 |
|---|---|---|
| `grilling` | モデル起動可 | 質問攻めの本体。1 度に 1 問、推奨回答付き、事実は自分で調べ決定だけ聞く。共通理解に達するまで実装に着手しない |
| `grill-me` | ユーザー専用 | `grilling` を明示起動する薄いラッパー（productivity カテゴリ） |
| `grill-with-docs` | ユーザー専用 | grilling + ドキュメント生成。固まった用語・決定を `CONTEXT.md` / ADR にセッション中に書き込む |
| `to-spec` | ユーザー専用 | 現在の会話を仕様書に合成して Issue トラッカーに発行。追加ヒアリングなし |
| `to-tickets` | ユーザー専用 | 計画・仕様・会話をトレーサーバレット型チケット群に分解。チケット間のブロック関係付き |
| `wayfinder` | ユーザー専用 | 1 セッションに収まらない巨大案件向け。「決定チケットの地図」を Issue 上に作り 1 つずつ解決 |
| `prototype` | モデル起動可 | 設計疑問に答える使い捨てプロトタイプ。状態/ロジック→ターミナルアプリ、UI→切替可能な複数案 |

## 実装フェーズ

| スキル | 起動 | 役割 |
|---|---|---|
| `implement` | ユーザー専用 | 仕様/チケットから実装を統括。合意済みシームで `/tdd` を回し、コミット前に `/code-review` で締める |
| `tdd` | モデル起動可 | red-green-refactor のテスト駆動開発。縦切りスライス単位で進める |
| `diagnosing-bugs` | モデル起動可 | 難バグ・性能劣化の診断ループ: 再現 → 最小化 → 仮説 → 計測 → 修正 → 回帰テスト |
| `resolving-merge-conflicts` | モデル起動可 | merge/rebase コンフリクトをハンク単位で、両側の意図を一次情報まで遡って解決。`--abort` しない |

## レビュー・運用フェーズ

| スキル | 起動 | 役割 |
|---|---|---|
| `code-review` | モデル起動可 | 固定点以降の差分を 2 軸並列レビュー: Standards（規約 + Fowler スメル）× Spec（元 Issue/PRD に忠実か） |
| `triage` | ユーザー専用 | Issue/外部 PR をステートマシンで流す: 分類 → 検証 → 必要なら grill → エージェント実行可能なブリーフ作成 |

## 設計・知識基盤（他スキルの土台）

| スキル | 起動 | 役割 |
|---|---|---|
| `codebase-design` | モデル起動可 | deep module 設計の共通語彙（小さいインターフェース、きれいなシーム、インターフェース越しのテスト） |
| `domain-modeling` | モデル起動可 | ドメインモデル・ユビキタス言語の構築。`CONTEXT.md`（用語集）と ADR を維持 |
| `improve-codebase-architecture` | ユーザー専用 | コードベースを deepening 機会についてスキャン → HTML レポート → 選んだ項目を grill |
| `research` | モデル起動可 | 一次情報ベースの調査を引用付き Markdown として repo に保存。バックグラウンド実行 |

## メタ

| スキル | 起動 | 役割 |
|---|---|---|
| `ask-matt` | ユーザー専用 | 「今の状況にどのスキルが合うか」を答えるルーター。迷ったらこれ |
| `setup-matt-pocock-skills` | ユーザー専用 | リポジトリごとの初期設定。Issue トラッカー / トリアージラベル / ドメインドキュメント構成を `docs/agents/*.md` に記録。**リポジトリごとに 1 回実行が必要** |

## grill 系の使い分け

- 思考を叩いてほしいだけ（コード以外の判断でも OK）→ `/grill-me` または「この計画を grill して」
- 叩いた結果を ADR・用語集として repo に残したい（設計判断向け）→ `/grill-with-docs`

## セットアップ済みリポジトリ

- `hermes-managements` — GitHub Issues / デフォルト 5 ラベル / single-context（2026-07-18 設定）
