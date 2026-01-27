---
name: basic-design-orchestrator
description: システム開発の基本設計をオーケストレーションし、最終成果物をMarkdown 1枚で出力する。画面基本設計、API設計、DB設計、バッチ設計、IF設計、アーキテクチャ設計、NFR整理（性能・可用性・運用・セキュリティ）に対応し、Mermaid図を含む。情報不足時は推測せず最大5件の確認質問を出して停止する。
---

# Basic Design Orchestrator

## 目的

- 基本設計を「1枚Markdown」に落とし込みやすい形で半自動化する
- 設計対象（UI/API/DB/Batch/NFR/複合）を判定し、該当テンプレ（references）を読み分けて章を組み立てる
- 不足情報が多い場合は先に確認質問を出し、無理に進めない

## 重要ルール（必ず守る）

- 推測で埋めない。必要情報が欠ける場合は「確認質問（最大5件）」のみ出して停止する
- 可能な限り「最終成果物 = Markdown 1枚」を守る（章を増やしても同一ファイル内で完結させる）
- 章の中で「一覧 → 個別詳細」（API/DB/Batch）を採用する
- 図は Mermaid を使う（必要な最小限だけ）

## クイックスタート（手順）

1. 設計対象を判定する（UI / API / DB / Batch / NFR / 複合）
2. `references/routing.md` を読んで、今回読むべきテンプレを決める
3. `references/template-base.md` の骨格に沿って、必要な章だけ残す
4. 対象別テンプレ（`references/ui.md` 等）から章を生成して差し込む
5. `references/final-gate.md` の観点で最終チェックし、未決事項・意思決定ログを確実に残す

## 読むべきリファレンス（擬似モジュール）

- Step-Auto（入力→作業→出力→ゲート）: `references/step-auto.md`
- ルーティング: `references/routing.md`
- 1枚Markdown骨格: `references/template-base.md`
- 画面設計: `references/ui.md`
- API設計: `references/api.md`
- DB設計: `references/db.md`
- バッチ設計: `references/batch.md`
- NFR: `references/nfr.md`
- 最終ゲート: `references/final-gate.md`
- 確認質問バンク: `references/question-bank.md`
- 図テンプレ（Mermaid）: `references/diagrams.md`

## 出力フォーマット（固定）

- 出力は「Markdown本文」だけにする（前置き説明は不要）
- 不足情報がある場合は、Markdown本文ではなく「確認質問」だけを出す
- 箇条書きは短く、表は列を固定し、見出し階層は崩さない
