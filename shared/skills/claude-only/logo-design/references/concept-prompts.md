# Concept exploration prompts (Codex CLI / image_gen)

Templates for Phase 2. One concept = one `codex exec` invocation, run in
parallel as background Bash tasks. `n` (image-count) parameters produce
same-idea variations — useless for exploration, so never rely on them.

## Diversity allocation

Image models collapse toward one aesthetic when asked for "N logo ideas" in
a single prompt. Force divergence by assigning each invocation a distinct
compositional system:

| # | System | Prompt fragment |
|---|---|---|
| 1 | Pure geometry | "built from 1–2 bold geometric primitives (circle, triangle, square) with boolean cuts" |
| 2 | Dot matrix | "constructed as a dot matrix / halftone arrangement (grid, concentric, or hex)" |
| 3 | Line system | "flowing line system — parallel strokes, wave, or spiral with consistent stroke weight" |
| 4 | Geometry × negative space | "a geometric silhouette where the key motif appears in negative space" |
| 5 | Line × letterform | "the letter '<X>' abstracted into a continuous line or monoline path" |
| 6 | Node / layer network | "connected nodes or stacked translucent layers suggesting structure" |

Generating 4? Use rows 1, 2, 3, and 5. The allocation is a floor, not a
ceiling — swap a row out if the brief clearly calls for something else
(e.g. mascot briefs need character sketches, not dot matrices).

## Image prompt template

```
Minimal flat vector-style logo concept for "<brand>", <domain/tone from brief>.
<diversity fragment for this slot>.
<color direction from brief>, flat solid colors, no gradients, no 3D, no shadows.
Centered on a plain white background with generous margin.
No text in the image.   ← drop this line only for wordmark/lettermark briefs
Clean enough to remain legible at 32x32 pixels.
```

Why these constraints: flat + solid + white background keeps the concept
close to what SVG can actually reproduce (Phase 4), and the 32 px clause
biases the model away from illustrative detail that would die in cleanup.

## Invocation

```bash
codex exec --skip-git-repo-check --sandbox workspace-write \
  -C "<workdir>/concepts/round-<k>" \
  "<image prompt>. Generate it with the image_gen tool and save it as concept-<n>.png in the current directory."
```

- `-C` + `--sandbox workspace-write` confines writes to the round directory.
- ~1 min per run; consumes ChatGPT-subscription quota, not API credits.
- Launch all concepts in the same turn (background Bash), then collect.
- If a run produces no PNG, check its stdout — codex may have saved under a
  different name; rename rather than regenerate.

## Iteration modifiers (round 2+)

Refining a picked direction — append to the original prompt:

- weight: "make the forms bolder / lighter"
- color: "restrict to <hex> on white" / "invert for dark background"
- composition: "tighter, single focal element, more negative space"
- hybrid: "combine the <element> of concept A with the <structure> of concept B"

Keep each refinement round to 2–4 images; breadth was round 1's job.
