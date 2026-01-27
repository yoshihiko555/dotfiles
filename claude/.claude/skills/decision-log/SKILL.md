---
name: decision-log
description: ADR/意思決定ログをコミットタイミングで作成・更新するための運用スキル。既存ADR/DECISIONSの形式に合わせ、会話履歴と差分から決定内容を要約して記録する。
metadata:
  short-description: ADR/意思決定ログ作成フロー
---

# decision-log

## 目的
- 実装が固まった「コミット直前」に、ADR と DECISIONS.md を一貫した形式で更新する
- 直前までのやり取り（方針決定の議論）とコミット対象の差分を踏まえて要約する

## 基本ルール
- 既存ADRがある場合は **最新ADRの構成・見出し・語調に合わせる**
- 既存ADRがない場合は **プロジェクトに配置済みのテンプレートMarkdown** を参照する
- 不明点は **最小限の確認質問**に留める
- 事実の捏造はしない（リンクや決定理由が不明なら確認）

## 変数（プロジェクトごとに読み替え）
- `{ADR_DIR}`: ADRディレクトリ（例: `docs/08_adr`）
- `{DECISIONS_PATH}`: 意思決定ログ（例: `{ADR_DIR}/DECISIONS.md`）
- `{ADR_PREFIX}`: ADRファイル名プレフィックス（例: `ADR`）
- `{DATE}` / `{DATE_NOSEP}` / `{NEXT_ID}` / `{TITLE}`
- `{ADR_TEMPLATE_DIR}`: プロジェクト内のテンプレ参照先
- `{ADR_TEMPLATE_SOURCE}`: 個人テンプレ保管場所（例: `/Users/yoshihiko/Dropbox/04_Development/81_Templates/03_ADR`）

## 実行フロー（コミット直前）
1. コミット対象の差分と、直前のやり取り（方針決定までの議論）を整理する
2. `{ADR_DIR}` 内の最新ADRを確認し、構成・見出し・語調を合わせる
3. `{DECISIONS_PATH}` を確認し、次の連番 `{NEXT_ID}` を決める
4. 新規ADRを作成: `{ADR_DIR}/{ADR_PREFIX}-{DATE_NOSEP}-{NEXT_ID}.md`
5. `DECISIONS.md` の ADR 一覧に1行追記（既存形式に合わせる）
6. 内容を見直し、必要なら修正
7. Git で **実装差分 + ADRファイル + DECISIONS.md** をまとめてコミット

## 既存ADRがある場合の作成プロンプト（汎用）
```
あなたはリポジトリのADR運用担当です。
次の方針に従って、ADRとDECISIONS.md更新を行ってください。

- ADRディレクトリ: {ADR_DIR}
- DECISIONS.md: {DECISIONS_PATH}
- 既存ADRの最新ファイルを参照し、見出し構成・文体・項目を合わせる
- ファイル名は {ADR_PREFIX}-{DATE_NOSEP}-{NEXT_ID}.md
- 決定日は {DATE}
- タイトルは「{TITLE}」
- ADR本文に、背景/問題/選択肢/決定/影響/実装・運用メモ/宿題/検証 を含める
- DECISIONS.md の ADR 一覧に1行追記（既存形式に合わせる）
- コミットメッセージは日本語で、ADR作成が分かる内容にする
- このスレッドのやり取りと、コミット対象の差分を踏まえて決定内容を要約する
- 不明点があれば、最小限の確認質問のみを先に行う
```

## 既存ADRがない場合の運用
- プロジェクト内に配置済みのテンプレートを参照してADRを作成する
- テンプレートが見当たらなければ、配置先を確認する（{ADR_TEMPLATE_DIR} / {ADR_TEMPLATE_SOURCE}）

## DECISIONS.md 追記フォーマット（例）
```
| {ADR_PREFIX}-{DATE_NOSEP}-{NEXT_ID} | {TITLE} | 採用 | {DATE} | 例）追従性/再現性/運用負荷 | 例）Docs/API/Automation |
```

## コミットメッセージ例
- `docs: ADR {ADR_PREFIX}-{DATE_NOSEP}-{NEXT_ID} を追加`
- `docs: 意思決定ログに {TITLE} を追加`
