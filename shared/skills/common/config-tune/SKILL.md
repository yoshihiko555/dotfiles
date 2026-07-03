---
name: config-tune
description: |
  ANALYSIS.md（/config-analyze の出力）に基づき対話的に設定ファイルを
  チューニングし、変更後にトリガーテストで効果を検証する。
  Skill/Agent/CLAUDE.md/Rule に対応。「スキルを改善して」「チューニングして」
  「description を直して」という依頼、または ANALYSIS.md 生成後の
  改善実行フェーズで使用する。
argument-hint: "<path/to/config-file> [--dry-run]"
allowed-tools: Read, Write, Edit, Glob, Grep, AskUserQuestion, Task
---

# config-tune

Interactively tune a configuration file based on its ANALYSIS.md, then verify
the result. Companion to `/config-analyze`.

## Inputs

- `$ARGUMENTS`: Path to the target configuration file, optionally followed by
  `--dry-run` (show proposals only, apply nothing).

## Phase 1: Preparation (automatic)

1. Parse `$ARGUMENTS` into file path and `--dry-run` flag.
2. Read the target file. If missing, report an error and stop.
3. Read `ANALYSIS.md` from the same directory. If missing, inform the user,
   run the `/config-analyze` procedure on the target first, then read the
   generated ANALYSIS.md.
4. Load the rubric from `references/rubric.md` (relative to this skill).

## Phase 2: Issue Presentation (Japanese)

Present the tuning recommendations from ANALYSIS.md:

```
🔧 チューニング対象: {filename}
種別: {type}

━━━ チューニング推奨事項 ━━━

🔴 高優先度:
  1. {issue title} — {brief description}

🟡 中優先度:
  2. {issue title} — {brief description}

🟢 低優先度:
  3. {issue title} — {brief description}
```

## Phase 3: Policy Decision (interactive)

Use AskUserQuestion — "どの項目を改善しますか？":

- "高優先度のみ" / "高 + 中優先度" / "番号指定" / "キャンセル"

"番号指定" → follow up for the numbers. "キャンセル" → stop and report.

## Phase 4: Improvement Execution (interactive, per item)

For each selected item:

### 4a. Generate improvement proposal

Ground each proposal in the rubric axis that flagged the issue. When editing,
follow the rubric's own guidance (motivate constraints instead of adding
ALL-CAPS MUSTs, prefer deleting over adding, one default + escape hatch).

**Language rules:**
- User-facing explanations: Japanese
- Configuration file content (edits): keep the file's existing language
  (this repo's skills use English bodies for token efficiency)
- ANALYSIS.md content: Japanese

### 4b. Present preview

```
━━━ 項目 {N}: {issue title} ━━━

📋 変更内容:
{what changes and why, tied to the rubric axis}

📝 Before:
{current section, abbreviated if long}

📝 After:
{proposed content}
```

### 4c. Get user confirmation

Use AskUserQuestion — "この変更を適用しますか？":
- "適用" — apply with Edit (in `--dry-run`, record only and note
  "（dry-run: 変更は適用されません）")
- "修正指示" — take feedback, revise, repeat from 4b
- "スキップ" — next item

## Phase 5: Verification (automatic, skip in --dry-run)

Run after all items are processed, when at least one change was applied.

### 5a. Trigger test (Skill only, when name/description changed)

The description is the only signal for skill discovery, so test it in
isolation:

1. Take the test queries from ANALYSIS.md「トリガーテスト案」(should-trigger
   5 / should-not-trigger 5). If absent, generate them per the same rules.
2. Spawn a fresh subagent (Task tool) with ONLY this context — no access to
   this conversation: the tuned skill's name + new description, the names +
   descriptions of 3-5 sibling skills as distractors, and the 10 queries.
   Instruct it: "For each query, answer which skill (if any) you would
   invoke. Return a query → skill table only."
   A fresh subagent matters because this conversation already knows the
   skill's full body and would over-trigger.
3. Score: should-trigger hit rate and should-not-trigger false-fire rate.
4. If any should-trigger query misses: revise the description (add the
   missing trigger vocabulary), re-run once. If it still misses after 2
   attempts, report the failing queries and leave the decision to the user.

### 5b. Behavior smoke test (optional, ask the user)

For changes beyond the description (procedure, output format), offer via
AskUserQuestion to run one representative task from the skill's use cases in
a fresh subagent given the tuned file as its instructions, and check the
output against the skill's own success criteria. Skip on "不要".

### 5c. Re-analysis

Re-run the `/config-analyze` scoring (Steps 4-5 of that skill) on the
modified file and regenerate ANALYSIS.md, so the next tuning cycle starts
from current data.

For full evals / benchmarking (baseline comparison, pass-rate statistics,
blind A/B), point the user to the skill-creator plugin — Claude Code only.

## Phase 6: Summary (automatic)

```
━━━ チューニング完了 ━━━

📊 変更一覧:
  ✅ {item 1}: {brief description}
  ⏭️ {item 3}: スキップ

🧪 検証結果:
  トリガーテスト: should-trigger {N}/5 発火 / should-not {N}/5 誤発火
  スモークテスト: {実施結果 / 未実施}

📈 ルーブリック変化:
  {axis}: {before} → {after}

ANALYSIS.md を再生成しました。
```

If `--dry-run`:
```
ℹ️ dry-run モードのため、変更・検証は行っていません。
適用するには --dry-run を外して再実行してください。
```

## Constraints

- NEVER modify the target file without explicit user approval for each change
- In `--dry-run` mode, never Edit/Write the target and skip Phase 5
- All user interaction in Japanese; file content keeps its existing language
- If ANALYSIS.md has no recommendations, report
  "チューニング推奨事項はありません" and stop
- Address High items before Medium, Medium before Low
- Trigger-test subagents must be context-isolated (5a step 2) — results from
  a subagent that saw the skill body are not valid
