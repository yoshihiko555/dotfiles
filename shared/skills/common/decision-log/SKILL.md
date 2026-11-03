---
name: decision-log
description: ADR（Architecture Decision Record）と意思決定ログ（DECISIONS.md）を、実装が固まりコミットする直前に作成・更新する運用スキル。既存ADR/DECISIONSの形式・見出し・語調に合わせ、直前の会話履歴とコミット差分から決定内容を抜き出して記録する。「ADRを書いて」「意思決定ログに追記して」「この決定を記録してからコミットして」といった依頼や、コミット前に設計判断を残したい場面で使用する。
allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(git diff:*), Bash(git add:*), Bash(git commit:*)
metadata:
  short-description: ADR/意思決定ログ作成フロー
---

# decision-log

## 目的
- 実装が固まった「コミット直前」に、ADR と DECISIONS.md を一貫した形式で更新する
- 会話と差分から **決定** を抜き出して残す。作業の経過や実装の詳細は ADR ではなくコミット本文・コード・docs に置く

## 基本ルール
- 書く前に **`references/GUIDELINE.md` を必ず読む**。何を ADR に書き、何を書かないかはここで決まっている
- 見出し・語調は `references/ADR.md` のテンプレートに従い、既存 ADR の語調に寄せる。
  既存 ADR の慣習が GUIDELINE と食い違う場合は GUIDELINE を優先する（既存 ADR は書き直さない）
- プロジェクトの AGENTS.md / CLAUDE.md に ADR の置き場所の定めがあれば、それに従う
- 不明点は **最小限の確認質問**に留める
- 事実の捏造はしない（リンクや決定理由が不明なら確認する）

## 変数（プロジェクトごとに読み替え）

| 変数 | 必須 | 取得方法 | 例 |
|------|------|---------|-----|
| `{ADR_DIR}` | 必須 | プロジェクトの定めを確認し、なければ `Glob` で `**/adr/**` を探索。複数候補・未検出時はユーザーに確認 | `docs/adr` |
| `{DECISIONS_PATH}` | 必須 | `{ADR_DIR}/DECISIONS.md` | `docs/adr/DECISIONS.md` |
| `{ADR_PREFIX}` | 必須 | 既存ADRファイル名から推定。既存ADRがない場合は `ADR` | `ADR` |
| `{DATE}` | 自動 | 実行日（YYYY-MM-DD） | `2026-02-08` |
| `{DATE_NOSEP}` | 自動 | 実行日（YYYYMMDD） | `20260208` |
| `{NEXT_ID}` | 自動 | `{ADR_DIR}` 内の最終連番 +1（4 桁）。初回は `0001` | `0005` |
| `{SLUG}` | 必須 | 決定内容を表す英小文字のケバブケース | `api-auth-method` |
| `{TITLE}` | 必須 | 採る方式を 1 文で（例:「API 認証に署名付きトークンを使う」） | — |

## 実行フロー（コミット直前）
1. 差分（`git diff --cached`）と直前のやり取りから、**決定を抜き出す**
   - 抜き出すもの: 何を採ったか / 何を捨てたか / 決め手 / 判断の根拠になった事実・実測 / 決めなかったこと
   - 抜き出さないもの: 試行錯誤の順序、段階ごとの計測値、作業の経過（コミット本文へ）
   - 決定が複数あれば ADR を分ける（GUIDELINE A-1）
2. `references/GUIDELINE.md` を読む
3. `{ADR_DIR}` の最新 ADR と `{DECISIONS_PATH}` を確認し、語調と次の連番 `{NEXT_ID}` を決める。
   既存 ADR がない場合は `references/DECISIONS.md` から索引を作る
4. `references/ADR.md` を元に、`{ADR_DIR}/{ADR_PREFIX}-{DATE_NOSEP}-{NEXT_ID}-{SLUG}.md` を作成する
5. `{DECISIONS_PATH}` の一覧に 1 行追記する（ADR へのリンク付き）
6. **点検**: 書き手とは別のコンテキストで、GUIDELINE に照らして点検させる（GUIDELINE G-2）
   - サブエージェント（Claude Code なら `Agent` ツール）に、下の「点検の依頼文」と ADR・索引・GUIDELINE のパスだけを渡す。
     会話の文脈は渡さない（ADR 単体で読めるかを見るため）
   - MUST の指摘はすべて直す。SHOULD は直すか、外す理由を ADR に書く
   - サブエージェントが使えない環境では、GUIDELINE の規約を 1 つずつ自分で照合する
7. 実装差分 + ADR + DECISIONS.md をまとめてコミットする。段階ごとの計測値や作業の経過はコミット本文に書く

### 点検の依頼文

```
次の ADR を、ガイドラインの規約に照らして点検してください。修正はせず、指摘だけを返してください。
- ADR: <ADR のパス>
- 索引: <DECISIONS.md のパス>
- ガイドライン: <GUIDELINE.md のパス>

指摘ごとに「規約番号（例: A-2）/ 強度（MUST・SHOULD）/ 該当箇所の引用 / 直し方」を書いてください。
「関連」や「決定しないこと」が指す文書は、実在するかを確かめてください。
規約に当てはまらない好みの指摘はしないでください。指摘がなければ「指摘なし」とだけ返してください。
```

## コミットメッセージ例
- 実装とまとめる場合: `feat(<領域>): <実装の説明>`（本文に ADR の ID を書く）
- ADR だけの場合: `docs(adr): {ADR_PREFIX}-{DATE_NOSEP}-{NEXT_ID} {TITLE}`

## 検証チェックリスト
- [ ] ADR ファイルが `{ADR_DIR}/{ADR_PREFIX}-{DATE_NOSEP}-{NEXT_ID}-{SLUG}.md` として存在する
- [ ] 「背景 / 選択肢 / 決定 / 検証 / 影響 / 決定しないこと」がある（「参照」は該当があれば）
- [ ] 点検役の MUST 指摘がすべて解消されている
- [ ] `{DECISIONS_PATH}` に正しい連番・リンク付きで 1 行追記されている
- [ ] コミットに実装差分・ADR ファイル・DECISIONS.md がすべて含まれている
