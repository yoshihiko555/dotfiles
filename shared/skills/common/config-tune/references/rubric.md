# Evaluation Rubric for Claude Code Configuration Files

Shared rubric used by both `/config-analyze` and `/config-tune`.

## Axes (6 total)

### 1. Structure Completeness — Priority: HIGH

Does the file cover all recommended sections for its type?

| Type | Recommended Sections |
|------|---------------------|
| Skill | Instructions, Inputs, Constraints, Output Format, Examples, Verification |
| Agent | Role, Capabilities, Output Format, Principles |
| CLAUDE.md | Project Context, Conventions, References |
| Rule | Trigger, Instructions, Examples |

**Scoring:**
- Good: All recommended sections present with substantive content
- Needs Improvement: 1-2 sections missing or only partially covered
- Missing: 3+ sections missing

### 2. Success Criteria Clarity — Priority: HIGH

Are completion conditions and verification methods explicitly defined?

**Scoring:**
- Good: Explicit "done when" conditions or verification steps present
- Needs Improvement: Implicit success criteria derivable from instructions
- Missing: No way to determine if the task was completed correctly

### 3. Token Efficiency — Priority: HIGH

Is the file free of redundancy? This is the most critical operational axis — every token in a configuration file consumes context window.

**Red flags:**
- Repeated instructions across sections
- Verbose explanations where a table or list suffices
- Boilerplate that adds no information
- Comments restating what the code already says
- Unnecessary formatting (excessive blank lines, decorative separators)

**Scoring:**
- Good: Concise, no redundancy, every line adds information
- Needs Improvement: Some redundancy or verbose sections (10-30% reducible)
- Missing: Significant redundancy (30%+ reducible)

### 4. Instruction Specificity — Priority: MEDIUM

Are instructions concrete and unambiguous?

**Red flags:**
- Vague verbs: "handle", "process", "manage", "deal with"
- Missing conditionals: "if X then Y" not specified for branching logic
- Undefined terms: using jargon without definition
- Ambiguous scope: unclear what is in/out of scope

**Scoring:**
- Good: All instructions actionable, conditionals explicit, no ambiguity
- Needs Improvement: 1-3 vague instructions or missing conditionals
- Missing: Pervasive vagueness, would require interpretation to follow

### 5. Example Quality — Priority: MEDIUM

Are few-shot examples present and useful?

**Scoring:**
- Good: 2+ concrete examples covering typical and edge cases
- Needs Improvement: 1 example or examples only cover the happy path
- Missing: No examples at all

### 6. Consistency — Priority: LOW

Does the file align with related configuration files in the same project/workspace?

**Check points:**
- Naming conventions match across files
- No contradictory instructions between related configs
- Shared terminology used consistently
- Tool references match actual available tools

**Scoring:**
- Good: Fully consistent with related files
- Needs Improvement: Minor inconsistencies (naming, formatting)
- Missing: Contradictions or significant misalignment with related configs

## Priority Mapping for Tuning

When generating tuning recommendations:

| Priority | Action |
|----------|--------|
| HIGH axis scored "Missing" | Critical — must fix |
| HIGH axis scored "Needs Improvement" | High priority |
| MEDIUM axis scored "Missing" | High priority |
| MEDIUM axis scored "Needs Improvement" | Medium priority |
| LOW axis scored "Missing" | Medium priority |
| LOW axis scored "Needs Improvement" | Low priority |
| Any axis scored "Good" | No action needed |
