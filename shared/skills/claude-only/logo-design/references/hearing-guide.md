# Hearing guide

Interview material for Phase 1. Ask only what the context scan could not
answer, and prefer AskUserQuestion with concrete options over open-ended
questions — options teach the user the vocabulary while they answer.

## Core items

| Item | Why it matters |
|---|---|
| Deliverable type | logo / single icon / icon set — changes every later phase |
| Brand name + wording | exact casing, abbreviation allowed? (e.g. "dotfiles" vs "DF") |
| Logo type | see taxonomy below; constrains composition fundamentally |
| Style axes | minimal↔detailed, geometric↔organic, classic↔modern, cool↔warm |
| Color direction | 1–2 brand colors, or monochrome-first; see color psychology |
| Usage contexts | dark terminal? tiny favicon? print? — drives contrast & simplicity |
| Anti-preferences | "not like X" is often the sharpest signal a user can give |

## Logo type taxonomy (7 types)

| Type | What it is | Example vocabulary |
|---|---|---|
| Wordmark | full name as styled text | Google, Notion |
| Lettermark | initials only | IBM, HP |
| Pictorial | recognizable concrete object | Apple, Twitter bird |
| Abstract | non-representational geometric form | Pepsi, Chase |
| Mascot | character/figure | GitHub Octocat |
| Combination | symbol + text locked together | Adidas |
| Emblem | text inside a badge/crest | Starbucks |

For app/CLI icons, Pictorial / Abstract / Lettermark are the realistic
choices — mascots and wordmarks die at 32 px.

## Color psychology (proposal material, not law)

| Color | Association | Common domains |
|---|---|---|
| Blue | trust, stability, competence | dev tools, finance, security |
| Green | growth, health, calm | env, wellness, fintech |
| Red / Orange | energy, urgency, warmth | consumer, food, entertainment |
| Purple | creativity, premium | design tools, luxury |
| Yellow | optimism, attention | education, kids |
| Black / Gray | sophistication, neutrality | fashion, pro tools, CLI |

Terminal/CLI tools skew monochrome + one accent: they must survive both
dark and light themes, and `currentColor` SVGs make that trivial.

## Icon-set extras

- Icon list: get explicit names (15–25 typical). Group by category
  (navigation / actions / status / domain-specific) and confirm coverage.
- Stroke vs fill: stroke sets read lighter and more modern; fill sets
  survive tiny sizes better. Pick one, never mix within a set.
- Grid: 24 px is the de-facto standard; 20 px for dense UIs.

## Brief format

Write `brief.md` so a subagent with zero conversation context can act on it:

```markdown
# Design brief: <name>
- Deliverable: <logo | app icon | icon set (N icons)>
- Brand: <name, exact wording/casing>
- Logo type: <one of the 7>
- Style: <chosen points on the four axes>
- Colors: <hex or direction; dark/light requirements>
- Usage: <contexts and minimum sizes>
- Avoid: <anti-preferences>
- Assumptions: <anything not confirmed by the user>
```
