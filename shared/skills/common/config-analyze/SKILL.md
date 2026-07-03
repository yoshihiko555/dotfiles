---
name: config-analyze
description: |
  Claude Code等の設定ファイル（Skill/Agent/CLAUDE.md/AGENTS.md/Rule）を解析し、
  公式ベストプラクティス準拠のルーブリックで採点した日本語ANALYSIS.mdと
  改善提案・トリガーテスト案を生成する。スキルの精度向上・レビュー・
  「このスキルを分析して」「設定を評価して」という依頼で使用する。読み取り専用。
argument-hint: "<path/to/config-file>"
allowed-tools: Read, Write, Glob, Grep
---

# config-analyze

Analyze a configuration file (Skill / Agent / CLAUDE.md / Rule) and generate a
Japanese ANALYSIS.md in the same directory. Read-only with respect to the
target file. The companion `/config-tune` consumes the ANALYSIS.md.

## Inputs

- `$ARGUMENTS`: Path to the target configuration file (required).
  If a directory is given and it contains `SKILL.md`, analyze that.

## Step 1: Read the target file

Read the file at `$ARGUMENTS`. If it does not exist, report an error and stop.

## Step 2: Detect file type

```
IF filename is "SKILL.md" OR frontmatter has skill fields
   (description + any of: allowed-tools, argument-hint, context, when_to_use) → Skill
ELSE IF path contains "/agents/" OR frontmatter has `name` + `description`
   with agent fields (tools / model)                                        → Agent
ELSE IF filename is "CLAUDE.md" OR "AGENTS.md"                              → CLAUDE.md
ELSE                                                                        → Rule
```

If ambiguous, ask the user; when running non-interactively (e.g. inside a
subagent), pick the closest type, state the assumption, and proceed.
Report the detected type in Japanese before proceeding.

## Step 3: Load rubric and context

1. Load the rubric: `~/.claude/skills/config-tune/references/rubric.md`
   (fall back to `references/rubric.md` relative to the config-tune skill
   directory if the path differs per CLI). If not found, report that scoring
   uses built-in knowledge and continue.
2. If the target has a `references/` or `scripts/` directory, list it and
   read each `references/*.md` (needed for the disclosure-structure checks).
3. For the Consistency axis, glance at sibling configs (same skills/ or
   agents/ directory) — names and descriptions only, not full bodies.
   If the target has no siblings (isolated copy, standalone file), score
   axis 7 on frontmatter validity and internal consistency alone and note
   the limitation in the report.

## Step 4: Measure

Collect objective metrics (from the Read output — no shell needed):

- Body line count (excluding frontmatter)
- `description` character count and approximate word count
- Frontmatter fields present; flag any not in the rubric's validation list
- Reference files: name, line count, has-TOC (for files over ~100 lines),
  and reference depth (does any references/ file link to another one?)
- Occurrences of vague verbs, ALL-CAPS MUST/NEVER, and rubric §5 red flags

## Step 5: Score against the rubric (7 axes)

Score each axis Good / Needs Improvement / Missing / N/A per the rubric's
scoring criteria, citing the Step 4 measurements as evidence. Axis 1
(Description & Trigger Quality) is N/A for CLAUDE.md and Rule files.

## Step 6: Generate ANALYSIS.md

Write `ANALYSIS.md` next to the target file. All content in Japanese.
Cite line numbers for every finding so `/config-tune` can act on them.

```markdown
# 解析レポート: {file name}

## 基本情報

| 項目 | 内容 |
|------|------|
| 種別 | {Skill / Agent / CLAUDE.md / AGENTS.md / Rule} |
| 名前 | {name} |
| ファイルパス | {absolute path} |
| 本文行数 | {N} 行（目安: Skill は 500 行未満） |
| description | {N} 文字 / 約 {N} 語（上限 1024 文字、目安 100-200 語） |
| 概要 | {1-2 sentence summary} |

## 目的・ユースケース

- 解決する問題: ...
- 使用場面: ...

## description 評価（Skill / Agent のみ）

- 現行 description の引用
- ルーブリック軸1チェックリストの各項目: ✅ / ❌ + 理由
- 改善が必要な場合: 改善版 description の提案文

## 内容の要約

{Japanese summary of the main instructions, organized by section}

## 構造評価

推奨要素（ルーブリック「Recommended Elements by Type」参照）ごとに:

| 推奨要素 | 状態 | 備考（行番号つき） |
|---------|------|------|
| {element} | ✅ 充足 / ⚠️ 部分的 / ❌ 欠落 / ➖ 不要 | {note} |

「❌ 欠落」は、その欠落が実害を生む場合のみ挙げる。動いているスキルに
セクションを足すことが目的化しないよう、「➖ 不要」の判定を積極的に使う。

## ルーブリック評価

| 軸 | 優先度 | 評価 | 根拠（測定値・行番号） |
|----|--------|------|------|
| 1. Description・トリガー品質 | 高 | ... | ... |
| 2. Progressive Disclosure・トークン予算 | 高 | ... | ... |
| 3. 成功基準・検証可能性 | 高 | ... | ... |
| 4. 指示の品質 | 中 | ... | ... |
| 5. アンチパターン | 中 | ... | ... |
| 6. 使用例の質 | 中 | ... | ... |
| 7. 一貫性・互換性 | 低 | ... | ... |

## チューニング推奨事項

{Prioritized list. Each item:}
- 優先度: 高 / 中 / 低（ルーブリックの Priority Mapping に従う）
- 対象: {section / axis} （行番号）
- 現状: ...
- 提案: 具体的な変更内容（可能なら Before/After の文面まで）

## トリガーテスト案（Skill のみ）

`/config-tune` の検証フェーズで使うテストクエリ。

- 発火すべきクエリ（should-trigger）5 件: 実際のユーザーが打ちそうな、
  ファイル名や固有名詞を含む生々しい文。抽象文は不可。
- 発火すべきでないクエリ（should-not-trigger）5 件: キーワードは近いが
  本来別のスキル/素の対話で扱うべき紛らわしい文。無関係すぎる文は不可。

## 補足

- 他CLI（Codex / Gemini）と共有されている場合: Claude 固有 frontmatter の
  適用可否を明記
- 本格的な eval / ベンチマークが必要な場合: skill-creator プラグイン
  （Claude Code 専用）の利用を案内
```

### Type-specific additions

- **Skill** — 「処理フロー」: numbered flow, 入出力仕様, 使用ツール一覧
- **Agent** — 「ロール定義」: 役割 / ツール割り当て / 出力フォーマット
- **CLAUDE.md** — 「セクション構成」: section/line-count table, スコープ,
  他設定との重複。手順書化しているセクションは「スキルへの切り出し候補」
  として必ず指摘する（CLAUDE.md は常時ロードされるため）
- **Rule** — 「適用ルール」: トリガー条件 / 委譲パターン / 適用範囲

## Step 7: Report summary

```
📄 {filename} の解析が完了しました。

種別: {type}
本文: {N} 行 / description: {N} 文字
ルーブリック: 高優先度軸 {Good数}/{対象軸数} Good
高優先度の課題: {count} 件 / 中: {count} 件 / 低: {count} 件

ANALYSIS.md を {path} に生成しました。
次のステップ: /config-tune {target path} で対話的に改善できます。
```

## Constraints

- ANALYSIS.md is always written in Japanese
- Do NOT modify the target file — this skill is read-only analysis
- Every finding cites a line number or measured value — no impressionistic
  scoring, so that tune-phase edits and re-analysis are comparable
- Keep the analysis factual — do not speculate about intent beyond the file
