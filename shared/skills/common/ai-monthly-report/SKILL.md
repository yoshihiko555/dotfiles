---
name: ai-monthly-report
description: |
  AI業界の月次レポートを自動生成する。対象はOpenAI、Anthropic、Google、Microsoftの4社。

  使用タイミング：
  - 「AI月次レポートを作成して」「今月のAIニュースをまとめて」等の依頼
  - 特定月のAI業界動向のサマリーが必要な時
  - 「1月のAIニュースを教えて」のような月指定の依頼
metadata:
  short-description: AI業界月次レポート自動生成
---

# ai-monthly-report

## 目的
AI業界（OpenAI、Anthropic、Google、Microsoft）の月次動向をWeb検索ベースで収集し、Markdownレポートとして出力する。

## 基本ルール
- 情報ソースはWeb検索ベース（X投稿も検索経由で取得）
- レポートトーンは客観的ニュースまとめ（分析・所感は入れない）
- 読者向け: 自分用メモ → チーム共有へ展開
- 出力形式: Markdown（さっと読める要約形式）

## 対象企業
1. **OpenAI** - ChatGPT、GPT系モデル、Codex CLI
2. **Anthropic** - Claude、Claude Code
3. **Google** - Gemini、Gemini CLI
4. **Microsoft** - Copilot、Azure OpenAI

## レポート構成
1. **今月のハイライト** - 3〜5項目のトップニュース
2. **主要AIニュース・発表** - 企業別の時系列表
3. **今月のリリースノート要点** - モデル別の技術的変更点
4. **今月のバズ・トレンド** - バズったX投稿（表形式）+ 詳細解説
5. **今月の数字** - 市場シェア、ユーザー数等の統計
6. **来月の注目点** - 予告・噂・注目イベント
7. **所感・メモ欄** - ユーザー記入用の空欄

## 実行フロー

### Step 1: パラメータ確認
- 対象月を確認（指定なければ前月）
- 出力先を確認（指定なければカレントディレクトリ）

### Step 2: 情報収集（Web検索）
`references/search-patterns.md` のパターンに従って検索:
1. 企業別ニュース検索
2. リリースノート・changelog検索
3. バズ投稿検索
4. 統計・数字検索

### Step 3: レポート生成
`assets/report-template.md` をベースに、収集情報を埋め込む

### Step 4: 出力
- ファイル名: `ai_monthly_report_{YYYYMM}.md`
- 例: `ai_monthly_report_202501.md`

## 検索のコツ
- X（Twitter）のURLは直接取得不可だが、検索経由でニュース記事化された情報は取得可能
- バイラルツイートは主要メディアが記事化するため詳細取得可能
- 複数ソースを組み合わせると漏れが少ない

## リリースノート収集の観点
| カテゴリ | 収集すべき情報 |
|----------|---------------|
| 新パラメータ | thinking_level, reasoning_effort, media_resolution等 |
| API変更 | 新エンドポイント、廃止予定、breaking changes |
| ベンチマーク | SWE-bench, Terminal-Bench, GPQA等のスコア |
| 新機能 | Context Compaction, Dynamic Thinking等 |
| コスト変更 | 価格改定、トークン効率改善 |
| CLI/SDK更新 | 新コマンド、設定オプション |

## 注意事項
- 事実の捏造はしない
- 日付が不明な場合は「-」と記載
- 統計数値は出典を明記
