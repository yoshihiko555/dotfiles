# SVG engraving rules

Rules for the Phase 4 subagent producing final SVGs. The goal is a clean
vector interpretation of the chosen concept — capture its *idea* (composition,
rhythm, silhouette), not its pixels. Raster concepts contain rendering noise
(gradients, texture, uneven edges) that must NOT be traced.

## Canvas & geometry

- Logos / single icons: `viewBox="0 0 100 100"`, no width/height attributes.
  Icon sets: `viewBox="0 0 24 24"` (or the grid from style-spec.json).
- Optical center at (50,50); keep 10–15 units of margin to every edge.
- 1–2 core elements maximum. Negative space ≥ 40% of the canvas.
- Stroke width 2.5–4 (on the 100 grid) for monoline work; if the mark must
  survive 16 px, err toward 4+. Consistent width within one mark.
- Coordinates: ≤ 2 decimal places. Snap to the half-unit grid.
- No `transform` on the root or top-level groups — bake transforms into
  coordinates. No editor cruft (unused defs, empty groups, metadata).

## Color

- Monochrome marks and all icon-set icons: `fill="currentColor"` /
  `stroke="currentColor"` so the host page controls theming.
- Colored marks: hex values from the brief only; ≤ 3 distinct colors.
- Tonal depth via opacity tiers, not extra colors: background elements
  0.1–0.4, secondary 0.6–0.8, primary 1.0.
- No gradients unless the brief explicitly asks.

## Optical corrections

Geometric equality is not visual equality:

- Curved strokes read thinner than straight ones at the same width — thicken
  curves slightly.
- Pointed shapes (arrows, triangles, chevrons) look smaller than their
  bounding box — overshoot the boundary by ~0.5 units.
- Circles alongside squares: the circle needs ~2–3% more diameter to look
  the same size.

## Structure & accessibility

- `role="img"` plus `<title>` (brand name) and `<desc>` (one-line
  description) on deliverable SVGs.
- Meaningful group ids (`id="symbol"`, `id="wordmark"`) — a human will edit
  this file later.
- Wordmark text must be converted to paths (no `<text>`, no font
  dependencies); the SVG must render identically with zero external
  resources.

## Icon sets

- All icons in a set share: viewBox, stroke width, linecap/linejoin, corner
  radius, padding. Record these in `final/style-spec.json`:

```json
{
  "grid": 24, "padding": 2, "style": "stroke",
  "strokeWidth": 2, "linecap": "round", "linejoin": "round",
  "cornerRadius": 2, "color": "currentColor"
}
```

- Balance visual weight: a simple icon (e.g. "plus") must not look lighter
  than a complex one (e.g. "settings") — nudge sizes/weights to compensate.
- kebab-case filenames, one concept per file.

## QA checklist (machine-checkable — the caller re-verifies)

- [ ] viewBox correct and identical across a set; no width/height on root
- [ ] no `<text>` elements; no external refs (fonts, images, css)
- [ ] no root/top-level `transform`
- [ ] coordinates ≤ 2 decimals
- [ ] color count ≤ 3 (or all currentColor)
- [ ] `<title>` + `<desc>` present
- [ ] renders legibly at 16/32/64 px (check the preview strip)
- [ ] monochrome variant provided when the brief requires dark+light use
