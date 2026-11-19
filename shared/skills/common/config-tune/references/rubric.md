# Evaluation Rubric for Claude Code Configuration Files

Shared rubric used by `/config-analyze` and `/config-tune`.
Based on Anthropic's official skill-authoring best practices (platform.claude.com
"Skill authoring best practices", code.claude.com "Extend Claude with skills")
and the official skill-creator plugin methodology. Context files
(CLAUDE.md / AGENTS.md) use the dedicated CF1-CF6 axes instead — grounded in
Anthropic's Claude Code memory docs / best-practices guide, the agents.md
spec, and OpenAI's Codex prompting guide.

**Contents:** Target Model · Axes for Skill / Agent / Rule (1-7) · Model Fit
(MF) · Context-File Axes (CF1-CF6) · Frontmatter Validation Checklist ·
Recommended Elements by Type · Priority Mapping for Tuning

## Target Model

The same files are distributed to every CLI (Claude Code / Codex / Gemini /
pi) with no per-model variants. Tune against one base: the Claude model in
use — the model running the analysis, or the model the file pins in its
frontmatter (`model:`). Other CLIs are checked for compatibility only:
checks that are Claude-specific are marked [Claude]. Score them normally,
but note cross-CLI applicability in the analysis.

What reads as dated changes with every model release, so this rubric does
not list those patterns. The Model Fit axis delegates them to
`/claude-api prompt-audit`, which is bundled with Claude Code and updated
with its releases.

## Axes for Skill / Agent / Rule (7 total)

### 1. Description & Trigger Quality — Priority: HIGH

The `description` is the ONLY signal the model sees when deciding whether to
load a skill. This axis applies to Skill and Agent files; score it N/A for
CLAUDE.md and Rule files.

**Checklist (Skill):**
- Written in third person ("Analyzes...", not "I can..." / "You can...")
- States BOTH what it does AND when to use it
- Names the kinds of request that should trigger it; a few representative
  phrasings help, but the list doesn't grow one phrase per missed query
- Where a sibling skill overlaps, says when not to use this one and names
  that skill
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

## Model Fit (MF) — Priority: HIGH

Applies to every file type (Skill / Agent / Rule / Context). Does the text
fit the target model, or was it written for an older model or against a
project state that no longer holds?

**How to evaluate:** run `/claude-api prompt-audit` on the target file and
its `references/`, naming the target model. Its findings are this axis's
evidence (location, pattern, confidence, proposed replacement). Do not
re-derive the patterns from memory.

Also compare what the file says about each tool it calls (MCP tools, CLIs)
with that tool's current description. A contradiction is a high-confidence
finding. This part does not depend on prompt-audit.

**Scoring:**
- Good: No high- or medium-confidence findings
- Needs Improvement: 1-2 medium-confidence findings
- Missing: Any high-confidence finding, or 3+ medium-confidence findings
- N/A: prompt-audit is unavailable (not running in Claude Code) and the
  file calls no tools. State this in the analysis

Low-confidence findings and `flag` items are reported, not scored.

## Context-File Axes (CLAUDE.md / AGENTS.md) — CF1-CF6

Use these six axes INSTEAD of the seven axes above when the target is a
context file (CLAUDE.md, AGENTS.md, CLAUDE.local.md). Context files load
into every session unconditionally, so the evaluation logic differs from
skills (which load on demand). Score against the axis text below, including
its caveats — not against remembered folklore about context files.

### CF1. Content Taxonomy — Priority: HIGH

Each line must be something the agent cannot get any other way
(Anthropic's include/exclude table).

**Belongs here:** non-guessable commands; non-default code style; test-runner
preferences; repo etiquette (branch/merge/PR rules); project-specific
architecture decisions; environment quirks and non-obvious gotchas.
**Does not belong:** anything inferable from the code; standard language
conventions; detailed API docs (link instead); frequently-changing info;
tutorials and long explanations; file-by-file descriptions; self-evident
advice ("write clean code").
**Multi-step procedures** are misplaced: flag them as skill-extraction
candidates (a skill costs nothing until invoked; a context file pays every
session).

**Scoring:**
- Good: Every section classifies as "belongs here"
- Needs Improvement: 1-3 lines/sections misclassified
- Missing: Mostly tutorials, self-evident advice, or procedure dumps

### CF2. Per-line Necessity — Priority: HIGH

Anthropic's pruning test: "Would removing this line cause the agent to make
mistakes?" If no, the line is noise diluting the lines that do matter.

**Checklist:**
- Each bullet passes the pruning test
- No rule restated across sections or duplicated from a sibling context file
- No speculative additions: a line earns its place by an observed failure it
  prevents, or by a documented need of the target model (an MF finding),
  not by sounding prudent

**Scoring:**
- Good: Every line passes the test
- Needs Improvement: 1-3 lines fail
- Missing: 4+ lines fail, or clearly auto-generated filler present

### CF3. Enforcement Channel — Priority: HIGH

Prose is the weakest enforcement mechanism. A hard rule written as prose is
a candidate for a mechanical channel:

- "never push to main" → permission deny rule / PreToolUse hook
- "always run X after editing" → PostToolUse hook
- "use model M / env var E" → settings.json
- Keep in prose only what needs judgment (tone, priorities, escalation)

**Scoring:**
- Good: No hard rule left in prose that a hook/permission could enforce
- Needs Improvement: 1-2 hook/permission candidates still in prose
- Missing: 3+ mechanically enforceable rules living only in prose

### CF4. Concreteness & Verifiability — Priority: MEDIUM

Same bar as skill instructions: "Use 2-space indentation", not "Format code
properly". An instruction is well-formed when an outside reviewer could
check compliance from the transcript alone.

**Scoring:**
- Good: All instructions verifiable
- Needs Improvement: 1-3 vague items
- Missing: Pervasive vagueness

### CF5. Consumer Fit & Sync — Priority: MEDIUM

Identify the consumer from the path first, then apply its checks:

| Path pattern | Consumer |
|---|---|
| `claude/`, `~/.claude/`, any CLAUDE.md | Claude Code |
| `codex/`, `~/.codex/` | Codex CLI |
| `gemini/`, `~/.gemini/` | Gemini |
| repo-root AGENTS.md | all agents |

**Check points:**
- [Claude] CLAUDE.md composes via `@path` imports; manually duplicating a
  canonical AGENTS.md instead of `@AGENTS.md` + a thin Claude-specific
  addendum is a finding. Prose/tables are the Anthropic-recommended style.
- Codex injects AGENTS.md root-to-leaf as separate user messages and is
  trained to follow them closely. XML-tagged instruction blocks are an
  adherence technique from OpenAI's prompting guides — surface as an
  OPTION for Codex-only files, never as a requirement or for shared files.
- Shared/core content must stay agent-neutral: no tool names, syntax, or
  frontmatter that only one CLI understands.
- Sync: when sibling context files exist (several CLAUDE.md/AGENTS.md
  variants in one repo), diff them. Unintentional drift — same rule with
  diverged wording, or a fix applied to one copy only — is a finding.
  Intentional per-agent diffs belong in one clearly-marked section, not
  scattered edits.
- Do not recommend per-model variants (e.g. Fable/Opus/Sonnet copies of
  one file): this repo keeps one set of files and tunes it against the
  base model (see Target Model). One file per consumer CLI is the target
  state.

**Scoring:**
- Good: Consumer identified, checks pass, no unintentional drift
- Needs Improvement: Minor drift or one consumer-fit issue
- Missing: Contradictory copies, or single-CLI syntax shipped to other CLIs

### CF6. Token Cost & Size — Priority: LOW

Anthropic's guidance is ~200 lines per file. Treat size as a token-cost and
maintainability concern, not a compliance lever: the harm comes from
specific outdated or wrong lines, not from length. Never justify a cut with
"shorter files are obeyed better" — justify it with CF1/CF2/MF, and report
line count as cost.

**Scoring:**
- Good: Under ~200 lines, or every line over that justified under CF1/CF2
- Needs Improvement: Over ~200 lines with visible CF1/CF2 slack
- Missing: Several hundred lines of unpruned content

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
| Skill | Goal and constraints/scope; numbered steps only where order matters; input spec (`$ARGUMENTS`); output format template; verification criteria |
| Agent | Role & routing criteria; tool assignments; output format; decision principles |
| CLAUDE.md | Project facts (structure, commands); conventions; pointers to skills/docs. Procedures found here → recommend extracting to a skill |
| Rule | Trigger condition; directives; an example if the directive is ambiguous |

## Priority Mapping for Tuning

Applies to every axis: the seven Skill/Agent/Rule axes, MF, and the CF1-CF6
context-file axes.

| Priority | Action |
|----------|--------|
| HIGH axis scored "Missing" | Critical — must fix |
| HIGH axis scored "Needs Improvement" | High priority |
| MEDIUM axis scored "Missing" | High priority |
| MEDIUM axis scored "Needs Improvement" | Medium priority |
| LOW axis scored "Missing" | Medium priority |
| LOW axis scored "Needs Improvement" | Low priority |
| Any axis scored "Good" or "N/A" | No action needed |
