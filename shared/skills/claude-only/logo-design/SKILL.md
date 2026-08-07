---
name: logo-design
description: |
  ロゴ・アプリ/CLIアイコン・UIアイコンセットを作成するハイブリッドワークフロー。
  Codex CLI の画像生成（image_gen）で複数コンセプト画像を並列探索し、ユーザー
  レビューを経て Opus subagent が SVG に清書、複数サイズの PNG へ書き出す。
  「ロゴを作って」「アイコンが欲しい」「シンボルマーク/favicon/アプリアイコンを
  デザインして」「README にロゴを載せたい」「UI アイコンを揃えたい」など、
  ビジュアルアイデンティティに関わる依頼では「ロゴ」と明言されなくても必ず使用する。
argument-hint: "[brand/project name or brief]"
---

# logo-design

Hybrid identity-design workflow. Raster image generation (GPT via Codex CLI)
is fast and rich for *exploring* visual directions, but its output is not
editable or scalable. SVG hand-written by Claude is the opposite: precise,
version-controllable, infinitely scalable — but expensive to explore with.
So: explore wide with images, commit narrow with SVG.

Deliverable types covered: product logos (symbol + wordmark), single app/CLI
icons (macOS app, Alfred workflow, README badge), and UI icon sets.

## Output layout

Create a working directory (default `./logo-design/`, confirm location in
Phase 1 if the repo has an obvious assets convention):

```
logo-design/
├── brief.md                     # design brief from Phase 1
├── concepts/round-<k>/          # PNG concepts per review round
│   ├── concept-<n>.png
│   └── index.html               # comparison page
├── final/                       # SVG deliverables (+ style-spec.json for sets)
└── export/<name>/<size>.png     # rendered PNGs
```

## Phase 0 — Context scan

Before asking anything, read what the project already tells you: README,
package.json / pyproject / Cargo.toml, existing icons or brand assets, site
CSS with brand colors. Derive candidate brand name, domain, tone. Questions
you can answer yourself are questions you don't ask.

## Phase 1 — Hearing

Read `references/hearing-guide.md`, then interview with AskUserQuestion.
Cover: deliverable type, brand name/wording, logo type (7-type taxonomy),
style axes, color direction, usage contexts (dark terminals? tiny favicon?).
Icon sets additionally need: icon list, stroke-vs-fill, grid size.

Write the agreed brief to `brief.md`. Every later phase (and every subagent)
works from this file, so make it self-contained.

**Non-interactive mode**: if the request already contains a complete brief,
or says to proceed without questions, derive `brief.md` from the request +
context scan and note the assumptions you made at the top of the file.

## Phase 2 — Concept exploration (Codex CLI)

Preflight: `command -v codex` and `codex features list | grep image_generation`.

Read `references/concept-prompts.md` for the prompt templates and the
diversity allocation rule, then generate 4–6 concepts, **one `codex exec`
invocation per concept**, launched in parallel as background Bash tasks:

```bash
codex exec --skip-git-repo-check --sandbox workspace-write \
  -C "<workdir>/concepts/round-1" \
  "<image prompt>. Generate it with the image_gen tool and save it as concept-<n>.png in the current directory."
```

Each run takes ~1 minute and consumes ChatGPT-subscription quota (no API
key involved). The diversity allocation exists because image models collapse
toward one aesthetic when asked for "variations" — force genuinely different
directions instead.

Wait for the generations by polling for the expected PNG files (a short
sleep-and-recheck loop in Bash works). Do not end your turn to "wait for a
completion notification" — in subagent contexts none may arrive and the
workflow stalls.

**Fallback**: if codex is unavailable or image generation fails, tell the
user, then explore with 4–6 quick SVG sketches instead (same diversity rule,
rules from `references/svg-rules.md`). Breadth is reduced but the workflow
survives.

## Phase 3 — Review loop

Build `concepts/round-<k>/index.html` from `assets/preview-template.html`:
inject the concept list into `__ITEMS__` and a title into `__TITLE__`.
The page shows each concept large, on light/dark backgrounds, plus a
16/32/64 px strip — small-size legibility kills more logo ideas than taste
does, so surface it early. Open the page (`open <path>`) and ask for
reactions.

Iterate in numbered rounds (`round-2/`, `round-3/`…), never overwriting
earlier rounds — users often come back to a discarded direction. Per
feedback, either refine one direction (modifier prompts in
concept-prompts.md), mix elements of two concepts, or fire a fresh
diversity round. Repeat until the user commits to a direction.

## Phase 4 — SVG finalization (Opus subagent)

Spawn an Agent (`subagent_type: general-purpose`, `model: opus`) to engrave
the chosen direction into SVG. The subagent's prompt must contain:

- the absolute path of `brief.md` and the chosen concept PNG(s) — instruct
  it to Read both (it can view images)
- the absolute path of `references/svg-rules.md` — the engraving rules and
  QA checklist it must follow
- output targets: `final/<name>.svg` (+ monochrome variants when the brief
  asks for them; + `final/style-spec.json` for icon sets)
- the instruction that the goal is a *clean vector interpretation* of the
  concept's idea, not a pixel-faithful trace

For icon sets, batch ~5 icons per subagent run and pass `style-spec.json`
from the first batch to later batches so the set stays consistent.

When the subagent returns, verify its output against the QA checklist in
svg-rules.md yourself (it is machine-checkable on purpose), rebuild the
preview page with the SVGs, and show the user. Loop with the same subagent
until accepted.

## Phase 5 — Export

Render PNGs with the bundled script (auto-detects resvg / rsvg-convert /
inkscape / ImageMagick):

```bash
scripts/export.sh final/<name>.svg export/<name>/          # 16→1024 default
scripts/export.sh final/<name>.svg export/<name>/ 256 512  # explicit sizes
```

Finish with a short `final/README.md`: file inventory, minimum size,
clear-space note, and dark/light usage guidance. Offer (don't assume) repo
integration — replacing existing icon files is the user's call.
