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
- 既存ADRがない場合は **本スキルの `references/` 内テンプレート** を参照する
- 不明点は **最小限の確認質問**に留める
- 事実の捏造はしない（リンクや決定理由が不明なら確認）

## 変数（プロジェクトごとに読み替え）

| 変数 | 必須 | 取得方法 | 例 |
|------|------|---------|-----|
| `{ADR_DIR}` | 必須 | プロジェクト構成から特定 | `docs/08_adr` |
| `{DECISIONS_PATH}` | 必須 | `{ADR_DIR}/DECISIONS.md` | `docs/08_adr/DECISIONS.md` |
| `{ADR_PREFIX}` | 必須 | 既存ADRファイル名から推定 | `ADR` |
| `{DATE}` | 自動 | 実行日（YYYY-MM-DD） | `2026-02-08` |
| `{DATE_NOSEP}` | 自動 | 実行日（YYYYMMDD） | `20260208` |
| `{NEXT_ID}` | 自動 | DECISIONS.md の最終連番 +1 | `005` |
| `{TITLE}` | 必須 | ユーザー指定またはコミット内容から要約 | `API認証方式の選定` |

## 実行フロー（コミット直前）
1. コミット対象の差分（`Bash: git diff --cached`）と、直前のやり取りを整理する
2. `{ADR_DIR}` 内の最新ADRを確認し（`Glob` + `Read`）、構成・見出し・語調を合わせる
3. `{DECISIONS_PATH}` を確認し（`Read`）、次の連番 `{NEXT_ID}` を決める
4. 新規ADRを作成（`Write`）: `{ADR_DIR}/{ADR_PREFIX}-{DATE_NOSEP}-{NEXT_ID}.md`
5. `DECISIONS.md` の ADR 一覧に1行追記（`Edit`）
6. 内容を見直し、必要なら修正（`Read` + `Edit`）
7. Git で実装差分 + ADRファイル + DECISIONS.md をまとめてコミット（`Bash: git add && git commit`）

## 既存ADRがある場合の作成プロンプト（汎用）
```
以下の変数でADRとDECISIONS.mdを作成してください。
手順は「実行フロー」、制約は「基本ルール」に従うこと。

- ADRディレクトリ: {ADR_DIR}
- DECISIONS.md: {DECISIONS_PATH}
- ファイル名: {ADR_PREFIX}-{DATE_NOSEP}-{NEXT_ID}.md
- 決定日: {DATE}
- タイトル: {TITLE}
```

## 既存ADRがない場合の運用
- 本スキルの `references/ADR.md` と `references/DECISIONS.md` をテンプレートとして使用する

## DECISIONS.md 追記フォーマット（例）
```
| {ADR_PREFIX}-{DATE_NOSEP}-{NEXT_ID} | {TITLE} | 採用 | {DATE} | 例）追従性/再現性/運用負荷 | 例）Docs/API/Automation |
```

## コミットメッセージ例
- `docs: ADR {ADR_PREFIX}-{DATE_NOSEP}-{NEXT_ID} を追加`
- `docs: 意思決定ログに {TITLE} を追加`
- `feat: 実装差分の内容についての説明`

## 検証チェックリスト
- [ ] ADRファイルが `{ADR_DIR}/{ADR_PREFIX}-{DATE_NOSEP}-{NEXT_ID}.md` として存在する
- [ ] ADR本文に必須項目（背景/問題/選択肢/決定/影響）がすべて含まれている
- [ ] 既存ADRの見出し構成・語調と整合している
- [ ] `{DECISIONS_PATH}` に正しい連番で1行追記されている
- [ ] コミットに実装差分・ADRファイル・DECISIONS.md がすべて含まれている
