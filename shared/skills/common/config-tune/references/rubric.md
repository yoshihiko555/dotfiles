# Evaluation Rubric for Claude Code Configuration Files

Shared rubric used by `/config-analyze` and `/config-tune`.
Based on Anthropic's official skill-authoring best practices (platform.claude.com
"Skill authoring best practices", code.claude.com "Extend Claude with skills")
and the official skill-creator plugin methodology.

Primary target is Claude Code. Skills in this repo are symlink-shared with
Codex / Gemini — axes or checks that are Claude-specific are marked [Claude].
Score them normally, but note cross-CLI applicability in the analysis.

## Axes (7 total)

### 1. Description & Trigger Quality — Priority: HIGH

The `description` is the ONLY signal the model sees when deciding whether to
load a skill. This axis applies to Skill and Agent files; score it N/A for
CLAUDE.md and Rule files.

**Checklist (Skill):**
- Written in third person ("Analyzes...", not "I can..." / "You can...")
- States BOTH what it does AND when to use it
- Lists concrete trigger keywords/phrases users would actually say
- Key use cases front-loaded (truncation-safe)
- Length: aim for 100-200 words; hard limit 1024 chars; no `<` `>` characters
- Slightly assertive phrasing is good — models under-trigger by default
  ("Use when the user mentions X, Y, or asks to Z — even if they don't say
  the word X explicitly")

**Checklist (Agent):**
- Description tells the delegating model exactly which tasks to route here
- Includes trigger examples if routing is ambiguous with sibling agents

**Scoring:**
- Good: All checklist items satisfied
- Needs Improvement: What-it-does is clear but when-to-use / triggers weak
- Missing: Vague ("Helps with documents"), first/second person, or absent

### 2. Progressive Disclosure & Token Budget — Priority: HIGH

Config files load into a shared context window. Only metadata (name +
description) is always resident; the body loads on activation; bundled files
load on demand. Structure content so each level pays for itself.

**Checklist:**
- SKILL.md body under 500 lines; approaching it → split into `references/`
- Reference files are linked DIRECTLY from SKILL.md (one hop — no
  references/a.md → references/b.md chains; partial reads lose nested links)
- Reference files over ~100 lines start with a table of contents
- Scripts are execute-only (never require reading them into context)
- No redundancy: no repeated instructions across sections, no boilerplate,
  no explanations of common knowledge the model already has
- CLAUDE.md holds FACTS (project context, conventions); multi-step PROCEDURES
  belong in a skill where they cost nothing until used

**Scoring:**
- Good: Within budget, one-hop references, every paragraph earns its tokens
- Needs Improvement: Some redundancy or verbosity (10-30% reducible), or a
  long body that should be split
- Missing: Over budget with no disclosure structure, or 30%+ reducible

### 3. Success Criteria & Verification — Priority: HIGH

Are completion conditions and verification methods explicitly defined?

**Scoring:**
- Good: Explicit "done when" conditions or verification steps present
- Needs Improvement: Implicit success criteria derivable from instructions
- Missing: No way to determine if the task was completed correctly

### 4. Instruction Quality — Priority: MEDIUM

Are instructions concrete, well-motivated, and easy to follow?

**Checklist:**
- Imperative mood; concrete verbs (no "handle", "process", "deal with")
- Branching logic spelled out as explicit conditionals ("if X then Y")
- Explains WHY a constraint matters instead of ALL-CAPS "MUST"/"NEVER"
  (a wall of MUSTs is a smell — models follow motivated rules better)
- One recommended default + an escape hatch, not a menu of alternatives
- One term per concept (don't alternate "endpoint" / "URL" / "route")

**Scoring:**
- Good: All actionable, conditionals explicit, constraints motivated
- Needs Improvement: 1-3 vague instructions, unmotivated MUSTs, or option lists
- Missing: Pervasive vagueness; following it would require interpretation

### 5. Anti-patterns — Priority: MEDIUM

Official "do not do this" list. Each hit is a concrete fix candidate.

**Red flags:**
- Explaining common knowledge (what a PDF is, what git does)
- Time-sensitive content ("before Aug 2025 use old API") — isolate legacy
  notes in a collapsed/clearly-marked section or delete them
- Windows-style paths (`scripts\x.py`) — always forward slashes
- Unqualified MCP tool names — use `ServerName:tool_name`
- Assuming dependencies are installed without stating install steps
- Magic constants without a comment explaining their origin
- Scripts that punt error handling to the model instead of handling it

**Scoring:**
- Good: No red flags
- Needs Improvement: 1-2 red flags
- Missing: 3+ red flags

### 6. Example Quality — Priority: MEDIUM

Examples must earn their tokens. They matter most for output formats and
genuinely ambiguous instructions — not everywhere.

**Scoring:**
- Good: Output formats shown as templates; ambiguous behavior has an
  Input/Output example; no redundant happy-path padding
- Needs Improvement: Format templates missing where output structure matters,
  or examples that only restate the instructions
- Missing: Ambiguous instructions with no example at all

### 7. Consistency & Compatibility — Priority: LOW

**Check points:**
- Naming conventions and terminology match sibling config files
- No contradictions with related configs (CLAUDE.md vs skills vs agents)
- Frontmatter is valid — see checklist below
- [Claude] Claude-specific frontmatter (`context: fork`, `hooks`, `paths`,
  `agent`, `model`, `effort`, `disable-model-invocation`, `user-invocable`)
  is flagged when the skill is shared with Codex/Gemini

**Scoring:**
- Good: Fully consistent, valid frontmatter, cross-CLI implications noted
- Needs Improvement: Minor inconsistencies (naming, formatting)
- Missing: Contradictions or invalid/unknown frontmatter fields

## Frontmatter Validation Checklist (Skill)

- `name`: max 64 chars, lowercase kebab-case, no "anthropic"/"claude"
- `description`: non-empty, max 1024 chars, no `<` `>`
- Portable fields: `name`, `description`, `license`, `allowed-tools`,
  `metadata`, `compatibility`
- [Claude] extension fields (valid in Claude Code, ignored or broken
  elsewhere): `argument-hint`, `arguments`, `when_to_use`,
  `disable-model-invocation`, `user-invocable`, `disallowed-tools`, `model`,
  `effort`, `context`, `agent`, `hooks`, `paths`, `shell`
- Unknown fields → Consistency finding

## Recommended Elements by Type

Guidance, not a mandatory template — flag an element only when its absence
hurts one of the axes above. Do not force sections into a skill that works
without them (that trades Axis 2 for cosmetics).

| Type | Elements that usually pay for themselves |
|------|------------------------------------------|
| Skill | Step-by-step procedure; input spec (`$ARGUMENTS`); output format template; constraints/scope; verification criteria |
| Agent | Role & routing criteria; tool assignments; output format; decision principles |
| CLAUDE.md | Project facts (structure, commands); conventions; pointers to skills/docs. Procedures found here → recommend extracting to a skill |
| Rule | Trigger condition; directives; an example if the directive is ambiguous |

## Priority Mapping for Tuning

| Priority | Action |
|----------|--------|
| HIGH axis scored "Missing" | Critical — must fix |
| HIGH axis scored "Needs Improvement" | High priority |
| MEDIUM axis scored "Missing" | High priority |
| MEDIUM axis scored "Needs Improvement" | Medium priority |
| LOW axis scored "Missing" | Medium priority |
| LOW axis scored "Needs Improvement" | Low priority |
| Any axis scored "Good" or "N/A" | No action needed |
