# mattpocock/skills 使い分けガイド

[mattpocock/skills](https://github.com/mattpocock/skills) プラグイン（engineering + productivity）の各スキルの役割と使い分けメモ。

- 棚卸し基準: **v1.2.3**（user スコープ、2026-09-23 更新）。配布スキルは `plugin.json` の `skills` 配列に載っている **25 本**
- 実体: `~/.claude/plugins/cache/mattpocock/mattpocock-skills/<version>/skills/`
- 変更履歴は同ディレクトリの `CHANGELOG.md` が一次情報

## 全体像

「アイデア → 仕様 → チケット → 実装 → レビュー」の開発ライフサイクル全体をカバーするスキル集。

- **ユーザー起動専用**（14 本）: `/mattpocock-skills:<name>` と明示的に打ったときだけ動く（`disable-model-invocation: true`。ワークフローの起点になる大物系）
- **モデル起動可**（11 本）: 会話の文脈から Claude が自動で呼び出せる（日常作業の支援系）

## 典型的なワークフロー

1. アイデア段階: `/grill-with-docs` で計画を叩く（用語集・ADR が育つ）
2. `/to-spec` で仕様化 → `/to-tickets` でチケット分解
   - 1 セッションに収まらない巨大案件だけ `/wayfinder`。地図が晴れたら `/to-spec` に合流する（`/implement` に直行しない）
3. `/triage` でチケットをエージェント実行可能な状態に整備
4. `/implement` が `tdd` → `code-review` を駆動して実装・レビュー
5. 詰まったら `diagnosing-bugs` / `prototype` / `research` を随時投入。人間しかできない手作業が出たら `wizard`

## 計画・仕様化フェーズ

| スキル | 起動 | 役割 |
|---|---|---|
| `grilling` | モデル起動可 | 質問攻めの本体。決定木の「フロンティア」（前提が確定済みの質問）を**1 ラウンドにまとめて番号付きで出す**（v1.2.0 で 1 問ずつ → ラウンド制に変更）。各問に推奨回答付き、事実は自分で調べ決定だけ聞く。共通理解の確認が取れるまで着手しない |
| `grill-me` | ユーザー専用 | `grilling` を明示起動する薄いラッパー（作業ディレクトリ外・コード以外の判断向け） |
| `grill-with-docs` | ユーザー専用 | grilling + ドキュメント生成。固まった用語・決定を `CONTEXT.md` / ADR にセッション中に書き込む |
| `to-spec` | ユーザー専用 | 現在の会話を仕様書に合成して Issue トラッカーに発行。追加ヒアリングなし |
| `to-tickets` | ユーザー専用 | 計画・仕様・会話をトレーサーバレット型チケット群に分解。ブロック関係付き（ローカル運用時は `.scratch/<feature>/issues/<NN>-<slug>.md` に 1 チケット 1 ファイル） |
| `wayfinder` | ユーザー専用 | 巨大案件向け。「決定チケット（decision ticket）の地図」を Issue 上に作り 1 つずつ解決。調査チケットは `/research` subagent で並列消化 |
| `prototype` | モデル起動可 | 設計疑問に答える使い捨てプロトタイプ。ロジック → **単一 HTML ファイル**（状態パネル + ガイド付きシナリオ）、UI → 切替可能な複数案。成果物は `prototype/<name>` ブランチに証拠として残す（v1.2.0 でターミナルアプリ方式から変更） |
| `to-questionnaire` | ユーザー専用 | 自分だけでは答えられない判断を、知っている相手に渡す質問票（Markdown）にする。聞くのは「誰に送るか・何が欲しいか」だけ。`grill-me` の逆向き版 |

## 実装フェーズ

| スキル | 起動 | 役割 |
|---|---|---|
| `implement` | ユーザー専用 | 仕様/チケットから実装を統括。合意済みシームで `/tdd` を回し、コミット前に `/code-review` で締める |
| `tdd` | モデル起動可 | red-green-refactor のテスト駆動開発。縦切りスライス単位で進める |
| `diagnosing-bugs` | モデル起動可 | 難バグ・性能劣化の診断ループ: 再現 → 最小化 → 仮説 → 計測 → 修正 → 回帰テスト。v1.2.3 で出力中の秘匿情報を `<REDACTED>` 化する手順が入った |
| `resolving-merge-conflicts` | モデル起動可 | merge/rebase コンフリクトをハンク単位で、両側の意図を一次情報まで遡って解決。`--abort` しない |
| `wizard` | モデル起動可 | 人間しかできない手順（外部ダッシュボード操作、認証情報・CI secret 設定、一回限りの移行）を案内する対話式 bash スクリプトを生成。URL を開く→値を入力→`.env` / `gh secret` に書く、を段階ごとに進める。エージェント自身で実行できる手順には使わない |

## レビュー・運用フェーズ

| スキル | 起動 | 役割 |
|---|---|---|
| `code-review` | モデル起動可 | 固定点以降の差分を 2 軸並列レビュー: Standards（規約 + Fowler スメル）× Spec（元 Issue/仕様に忠実か） |
| `triage` | ユーザー専用 | Issue/外部 PR をステートマシンで流す: 分類 → 検証 → 必要なら grill → エージェント実行可能なブリーフ作成 |

## 設計・知識基盤（他スキルの土台）

| スキル | 起動 | 役割 |
|---|---|---|
| `codebase-design` | モデル起動可 | deep module 設計の共通語彙（小さいインターフェース、きれいなシーム、インターフェース越しのテスト）。「design it twice」手法も同梱 |
| `domain-modeling` | モデル起動可 | ドメインモデル・ユビキタス言語の構築。`CONTEXT.md`（用語集）と ADR を維持 |
| `improve-codebase-architecture` | ユーザー専用 | 直近コミットで変更が集中している箇所を優先して deepening 機会をスキャン → HTML レポート → 選んだ項目を grill |
| `research` | モデル起動可 | 一次情報ベースの調査を引用付き Markdown として repo に保存。バックグラウンド実行 |
| `writing-for-agents` | モデル起動可 | エージェント向け文書（スキル / `AGENTS.md` / `CLAUDE.md`）の書き方リファレンス。context pointer、情報階層、完了条件、leading word、否定形を避ける、などの原則集。旧 `writing-great-skills` |

## セッション運用・コミュニケーション

| スキル | 起動 | 役割 |
|---|---|---|
| `handoff` | ユーザー専用 | 会話を別エージェント向けの引き継ぎ文書に圧縮し OS の一時ディレクトリへ保存。既存成果物はパス参照、次に使うべきスキルも記載。**別ハーネス・別ディレクトリ・他人へ持ち出すときだけ**使う（同一環境なら `/clear` や `/compact` で足りる） |
| `wait-what` | ユーザー専用 | 直前の説明が分からなかったときの 1 語コマンド。短い文脈 + 平易な英語（ASD-STE100）+ `CONTEXT.md` の用語で言い直させる |
| `teach` | ユーザー専用 | カレントディレクトリを学習ワークスペースにして、複数セッションにまたがって教える。`MISSION.md` / 学習記録 / HTML レッスン / 参考資料を蓄積 |

## メタ

| スキル | 起動 | 役割 |
|---|---|---|
| `ask-matt` | ユーザー専用 | 「今の状況にどのスキルが合うか」を答えるルーター。フェーズ境界での判断（continue → `/clear` → `/handoff` → subagent → `/compact` の順に検討）も扱う。迷ったらこれ |
| `setup-matt-pocock-skills` | ユーザー専用 | リポジトリごとの初期設定。Issue トラッカー / トリアージラベル / ドメインドキュメント構成を `docs/agents/*.md` に記録。**リポジトリごとに 1 回実行が必要** |

## grill 系の使い分け

- 思考を叩いてほしいだけ（コード以外の判断でも OK）→ `/grill-me` または「この計画を grill して」
- 叩いた結果を ADR・用語集として repo に残したい（設計判断向け）→ `/grill-with-docs`
- 自分では答えられず、知っている人から聞き出したい → `/to-questionnaire`
- 1 問ずつに戻したい場合はグローバル `CLAUDE.md` に一行書けば opt-out できる（スキル側の仕様）

## 自作スキル・組み込み機能との重なり

呼び出し時に取り違えやすいもの。

| mattpocock 側 | 重なる相手 | 使い分け |
|---|---|---|
| `code-review` | 組み込み `/code-review` | 組み込みは正しさのバグ検出。mattpocock 版は「規約 × 仕様」の 2 軸。明示するなら `/mattpocock-skills:code-review` |
| `writing-for-agents` | 自作 `config-analyze` / `config-tune`、`skill-creator` | mattpocock 版は書き方の原則集（モデル起動）。採点・チューニング・eval は自作側 |
| `domain-modeling`（ADR） | 自作 `decision-log` | 当リポジトリの ADR / `DECISIONS.md` 形式に合わせるなら `decision-log` |
| `research` | 自作 `decision-brief` | 網羅的に調べて残すなら `research`、決定に効く点だけなら `decision-brief` |
| `grilling` | 自作 `premortem` | 対話で前提を詰めるなら grilling、AI に一方的に穴を挙げさせるなら premortem |

## 配布対象外（参考）

リポジトリには `skills/in-progress/`（ベータ: `pr`, `retro`, `loop-me` など 9 本）と `skills/misc/`（`setup-pre-commit`, `git-guardrails-claude-code` など 4 本）もあるが、プラグインには含まれない（skills.sh で個別導入する前提）。v1.2.0 で `ubiquitous-language` / `design-an-interface` / `qa` / `request-refactor-plan` は削除済み（それぞれ `domain-modeling` / `codebase-design` / `triage`+`to-tickets` / `to-spec`+`improve-codebase-architecture` に吸収）。

## セットアップ済みリポジトリ

- `hermes-managements` — GitHub Issues / デフォルト 5 ラベル / single-context（2026-07-18 設定）。※ project スコープで v1.2.0 のまま
