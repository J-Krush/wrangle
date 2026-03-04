#!/bin/bash
# polish-all-screenshots.sh — Batch process all raw screenshots into polished marketing images.
#
# Usage: ./scripts/polish-all-screenshots.sh [--radius N]
#
# Processes: screenshots/raw/*.png → screenshots/polished/

set -euo pipefail
cd "$(dirname "$0")/.."

RAW_DIR="screenshots/raw"
OUT_DIR="screenshots/polished"
RADIUS=24

while [[ $# -gt 0 ]]; do
    case "$1" in
        --radius) RADIUS="$2"; shift 2 ;;
        *)        shift ;;
    esac
done

mkdir -p "$OUT_DIR"

if ! ls "$RAW_DIR"/*.png &>/dev/null; then
    echo "No raw screenshots found in $RAW_DIR/"
    echo "Capture with: screencapture -l <windowID> -o $RAW_DIR/shot-N.png"
    exit 1
fi

count=0
for raw in "$RAW_DIR"/*.png; do
    name=$(basename "$raw" .png)
    echo "Processing: $name"
    python3 scripts/polish-screenshot.py "$raw" "$OUT_DIR/$name.png" --radius "$RADIUS"
    count=$((count + 1))
done

echo ""
echo "Polished $count screenshots → $OUT_DIR/"
