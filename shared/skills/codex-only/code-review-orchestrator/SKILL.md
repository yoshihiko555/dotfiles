---
name: code-review-orchestrator
description: "コードレビューをオーケストレーションし、diff/PR/ブランチ差分/全体レビューを重大度付きで出力する。Go/Next.js/TS/Python/DB/インフラの変更レビュー、未レビュー既存コードの整合性確認、lint/test/型チェック提案が必要なときに使う。"
---

# Code Review Orchestrator

## 概要
差分または全体コードを対象に、優先度順で観点別レビューを実行し、重大度・根拠・改善案を整理して提示する。

## ワークフロー決定
1. 入力タイプを判定する: diff / PR / ブランチ差分 / 全体レビュー
2. 情報不足なら最小限の確認をする
3. 収集 -> スコープ制限 -> 観点別レビュー -> 整合性確認 -> テスト提案 -> 出力

## 0. 前提確認（必要時のみ）
- レビュー対象の差分範囲・PR番号・ブランチ名
- 重大度基準の変更有無（デフォルトは references/severity.md）
- 全体レビューの最大ファイル数（デフォルト 30）
- 実行してよいコマンドの範囲（lint/test/型チェック）

## 1. 収集
- diff: `git diff` / `git diff --stat` で範囲確認
- PR: `gh pr view <num> --patch` を優先
- ブランチ差分: `git diff <base>...<head>`
- 全体レビュー: まずディレクトリ構造と主要エントリを把握

## 2. スコープ制限
- 全体レビューは **最大 30 ファイル** まで
- Phase 1: 地図化（構成と危険領域候補）
- Phase 2: 高リスク領域を優先的に深掘り
- Phase 3: 残りは代表サンプル
- 具体ルールは references/scope-limits.md を読む

## 3. 観点別レビュー（優先度順）
1. バグ
2. セキュリティ
3. 設計整合性
4. 性能
5. 可読性

観点ごとに独立してレビューし、最後に統合して出力する。

## 4. 全体整合性レビュー
- 層/境界/命名/依存/設定の整合性を確認
- 詳細は references/consistency.md を読む

## 5. テスト/静的解析の提案
- 変更内容に応じた lint/test/型チェックの候補を提示
- 実行はユーザー確認後
- 詳細は references/test-strategy.md を読む

## 6. 出力フォーマット
- 重大度順に並べる
- 形式は references/output-template.md に従う

## リソース
必要に応じて以下を読む。
- references/severity.md
- references/output-template.md
- references/scope-limits.md
- references/consistency.md
- references/test-strategy.md
- references/go.md
- references/nextjs-ts.md
- references/python.md
- references/db-infra.md
