#!/usr/bin/env bash
# Render an SVG to multiple PNG sizes with whichever renderer is installed.
# Usage: export.sh <input.svg> <output-dir> [size ...]
# Default sizes: 16 32 64 128 256 512 1024
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "usage: $0 <input.svg> <output-dir> [size ...]" >&2
  exit 1
fi

svg="$1"
outdir="$2"
shift 2
sizes=("$@")
[ ${#sizes[@]} -eq 0 ] && sizes=(16 32 64 128 256 512 1024)

[ -f "$svg" ] || { echo "error: $svg not found" >&2; exit 1; }
mkdir -p "$outdir"
base="$(basename "$svg" .svg)"

render() { # render <size> <out.png>
  local size="$1" out="$2"
  if command -v resvg >/dev/null 2>&1; then
    resvg --width "$size" --height "$size" "$svg" "$out"
  elif command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w "$size" -h "$size" "$svg" -o "$out"
  elif command -v inkscape >/dev/null 2>&1; then
    inkscape "$svg" --export-type=png --export-filename="$out" \
      --export-width="$size" --export-height="$size" >/dev/null 2>&1
  elif command -v magick >/dev/null 2>&1; then
    magick -background none -density 300 "$svg" -resize "${size}x${size}" "$out"
  else
    echo "error: no SVG renderer found (tried resvg, rsvg-convert, inkscape, magick)" >&2
    echo "hint: brew install resvg  # or librsvg / inkscape / imagemagick" >&2
    exit 1
  fi
}

for size in "${sizes[@]}"; do
  out="$outdir/${base}-${size}.png"
  render "$size" "$out"
  echo "wrote $out"
done
