---
name: config-analyze
description: |
  Claude Code設定ファイル（Skill/Agent/CLAUDE.md/AGENTS.md/Rule）を解析し、
  日本語ドキュメントと改善提案を生成する。
argument-hint: "<path/to/config-file>"
allowed-tools: Read, Write, Glob, Grep
---

# config-analyze

Analyze a Claude Code configuration file and generate a Japanese ANALYSIS.md in the same directory.

## Inputs

- `$ARGUMENTS`: Path to the target configuration file (required)

## Step 1: Read the target file

Read the file at `$ARGUMENTS`. If the file does not exist, report an error and stop.

## Step 2: Detect file type

Determine the file type using this logic:

```
IF file has YAML frontmatter:
  IF frontmatter contains `name` AND (`allowed-tools` OR `description` with skill-like content) → Skill
  IF frontmatter contains `name` AND `tools` AND `model` → Agent
ELSE (no frontmatter):
  IF filename is "CLAUDE.md" OR "AGENTS.md" → CLAUDE.md
  ELSE → Rule
```

Report the detected type to the user in Japanese before proceeding.

## Step 3: Load references

Check if a `references/` directory exists in the same directory as the target file.
If it exists, read all `.md` files inside it. These provide additional context for analysis.

Also load the rubric from: `~/.claude/skills/config-tune/references/rubric.md`
If the rubric file is not found, use the built-in rubric criteria defined in Step 5.

## Step 4: Analyze structure

Compare the file's structure against the recommended structure for its type:

### Skill (6 sections)

| Section | Purpose |
|---------|---------|
| Instructions | Step-by-step procedure |
| Inputs | Arguments and input specification |
| Constraints | Scope and limitations |
| Output Format | Output structure |
| Examples | Usage examples |
| Verification | Success criteria |

### Agent (4 sections)

| Section | Purpose |
|---------|---------|
| Role | When and why to use this agent |
| Capabilities | Tools, skills, expertise |
| Output Format | Output structure and templates |
| Principles | Coding standards and decision criteria |

### CLAUDE.md / AGENTS.md (3 sections)

| Section | Purpose |
|---------|---------|
| Project Context | Project overview and structure |
| Conventions | Rules, standards, workflows |
| References | Links, skill list |

### Rule (3 sections)

| Section | Purpose |
|---------|---------|
| Trigger | When the rule applies |
| Instructions | Specific directives and patterns |
| Examples | Application examples |

For each recommended section, determine: present / partial / missing.

## Step 5: Evaluate against rubric (6 axes)

Score each axis as: Good / Needs Improvement / Missing.

| Axis | Priority | Evaluation criteria |
|------|----------|-------------------|
| Structure completeness | High | Coverage of recommended sections for the file type |
| Success criteria clarity | High | Presence of completion conditions and verification methods |
| Token efficiency | High | Absence of redundancy (critical for context management) |
| Instruction specificity | Medium | No vague verbs (handle, process, etc.), explicit conditionals |
| Example quality | Medium | Presence and quality of few-shot examples |
| Consistency | Low | Alignment with related configuration files |

## Step 6: Generate ANALYSIS.md

Write `ANALYSIS.md` in the same directory as the target file with the following structure.
All content MUST be in Japanese.

```markdown
# 解析レポート: {file name}

## 基本情報

| 項目 | 内容 |
|------|------|
| 種別 | {Skill / Agent / CLAUDE.md / AGENTS.md / Rule} |
| 名前 | {name from frontmatter or filename} |
| ファイルパス | {absolute path} |
| 概要 | {1-2 sentence summary in Japanese} |

## 目的・ユースケース

- 解決する問題: ...
- 使用場面: ...

## 内容の要約

{Japanese summary of the main instructions/rules, organized by section}

## {Type-specific section — see below}

## 構造評価

| 推奨セクション | 状態 | 備考 |
|--------------|------|------|
| {section name} | ✅ 充足 / ⚠️ 部分的 / ❌ 欠落 | {brief note} |

## ルーブリック評価

| 軸 | 優先度 | 評価 | 理由 |
|----|--------|------|------|
| 構造の完全性 | 高 | {Good/Needs Improvement/Missing} | {reason} |
| 成功基準の明確性 | 高 | {Good/Needs Improvement/Missing} | {reason} |
| トークン効率 | 高 | {Good/Needs Improvement/Missing} | {reason} |
| 指示の具体性 | 中 | {Good/Needs Improvement/Missing} | {reason} |
| 使用例の充実 | 中 | {Good/Needs Improvement/Missing} | {reason} |
| 一貫性 | 低 | {Good/Needs Improvement/Missing} | {reason} |

## チューニング推奨事項

{Prioritized list of improvement suggestions. Each item must include:}
- 優先度: 高 / 中 / 低
- 対象: Which section or aspect
- 現状: What is currently there (or missing)
- 提案: Specific improvement action
```

### Type-specific sections

Insert the appropriate section based on file type:

**For Skill — add "処理フロー":**
```markdown
## 処理フロー

1. {Step 1 description}
2. {Step 2 description}
...

### 入出力仕様

| 項目 | 内容 |
|------|------|
| 入力 | {inputs} |
| 出力 | {outputs} |

### 使用ツール一覧

- {tool 1}: {purpose}
- {tool 2}: {purpose}
```

**For Agent — add "ロール定義":**
```markdown
## ロール定義

- 役割: {role description}
- ツール割り当て: {list of tools}
- 出力フォーマット: {output format description}
```

**For CLAUDE.md / AGENTS.md — add "セクション構成":**
```markdown
## セクション構成

| セクション | 行数 | 内容概要 |
|-----------|------|---------|
| {section} | {lines} | {summary} |

### スコープ

{global / project}

### 他設定との重複

{Any overlap with rules, skills, or agents — or "特になし"}
```

**For Rule — add "適用ルール":**
```markdown
## 適用ルール

- トリガー条件: {when this rule activates}
- 委譲パターン: {delegation patterns, if any}
- 適用範囲: {scope of application}
```

## Step 7: Report summary

Output a brief Japanese summary to the conversation:

```
📄 {filename} の解析が完了しました。

種別: {type} (Skill / Agent / CLAUDE.md / AGENTS.md / Rule)
構造充足率: {N}/{total} セクション
高優先度の課題: {count}件
中優先度の課題: {count}件

ANALYSIS.md を {path} に生成しました。
```

## Constraints

- ANALYSIS.md is always written in Japanese
- Do NOT modify the target file — this skill is read-only analysis
- If the file type cannot be determined, ask the user to specify it
- Keep the analysis factual — do not speculate about intent beyond what the file states
