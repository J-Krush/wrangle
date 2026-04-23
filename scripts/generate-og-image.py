#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#     "Pillow>=10.0",
# ]
# ///
"""
generate-og-image.py — Render the social share / Open Graph preview image.

Produces a 1200x630 PNG that combines the Wrangle wordmark, an accented
headline, a subline, feature bullets, a footer line, and a rounded product
screenshot — matching the landing page visual style.

Recommended invocation (uv auto-installs Pillow in an ephemeral env):

    uv run scripts/generate-og-image.py

Or if Pillow is already on your PATH:

    python3 scripts/generate-og-image.py

With overrides:

    uv run scripts/generate-og-image.py \\
        --screenshot path/to/other.png \\
        --headline "your headline" --accent "word" \\
        --bullets "a,b,c,d" --output /tmp/out.png

Defaults match the current landing page copy; running with no args regenerates
Landing Page/public/images/og-image.png from the live screenshot.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print(
        "Error: Pillow not available.\n"
        "  Recommended:  uv run scripts/generate-og-image.py  (auto-installs)\n"
        "  Or:           pip3 install --break-system-packages Pillow",
        file=sys.stderr,
    )
    sys.exit(1)


# ── Brand tokens (match Landing Page/src/styles/global.css) ────────────────────
BG = "#0F0F12"
TEXT_PRIMARY = "#E5E5E5"
TEXT_SECONDARY = "#A3A3A3"
TEXT_TERTIARY = "#737373"
ACCENT = "#3DB8A8"

# ── Canvas ─────────────────────────────────────────────────────────────────────
W, H = 1200, 630
PAD_X = 80
PAD_Y = 64
COL_GAP = 40
LEFT_COL_W = 440
RIGHT_COL_W = W - PAD_X * 2 - LEFT_COL_W - COL_GAP

# ── Typography (in px, monospace) ──────────────────────────────────────────────
WORDMARK_SIZE = 32
HEADLINE_SIZE = 38
SUBLINE_SIZE = 18
BULLET_SIZE = 20
FOOTER_SIZE = 17

ICON_SIZE = 48
ICON_TEXT_GAP = 14
HEADLINE_TOP_GAP = 40       # below the icon+wordmark row
SUBLINE_TOP_GAP = 16        # below the headline
BULLETS_TOP_GAP = 28        # below the subline
BULLET_LINE_H = 36
SCREENSHOT_CORNER_RADIUS = 12

# ── Paths ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR = Path(__file__).resolve().parent
PROJECT_DIR = SCRIPT_DIR.parent
REPO_ROOT = PROJECT_DIR.parent
LANDING_DIR = REPO_ROOT / "Landing Page"

DEFAULT_SCREENSHOT = LANDING_DIR / "public/images/product-images/editor-simple.png"
DEFAULT_LOGO = LANDING_DIR / "public/images/wrangle-logo-13.png"
DEFAULT_OUTPUT = LANDING_DIR / "public/images/og-image.png"

# ── Default copy (kept in sync with landing page index.astro) ──────────────────
DEFAULT_HEADLINE = "the markdown editor built for AI-native development."
DEFAULT_ACCENT = "development."
DEFAULT_SUBLINE = "Claude Code · Gemini · AI agents"
DEFAULT_BULLETS = [
    "embedded terminals",
    "embedded browser",
    "smart notifications",
    "token counting",
]
DEFAULT_FOOTER = "$19 one-time · macOS · Apple Silicon"


# ── Font loading ───────────────────────────────────────────────────────────────
def load_mono(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    """Load a monospace font, walking a preference list. Menlo is the macOS fallback."""
    home_fonts = Path.home() / "Library/Fonts"
    if bold:
        candidates: list[tuple[str, int]] = [
            (str(home_fonts / "JetBrainsMono-Bold.ttf"), 0),
            ("/Library/Fonts/JetBrainsMono-Bold.ttf", 0),
            ("/Library/Fonts/SF-Mono-Bold.otf", 0),
            ("/System/Library/Fonts/Menlo.ttc", 1),  # Menlo.ttc faces: 0=Reg, 1=Bold, 2=Italic, 3=BoldItalic
        ]
    else:
        candidates = [
            (str(home_fonts / "JetBrainsMono-Regular.ttf"), 0),
            ("/Library/Fonts/JetBrainsMono-Regular.ttf", 0),
            ("/Library/Fonts/SF-Mono-Regular.otf", 0),
            ("/System/Library/Fonts/Menlo.ttc", 0),  # index 0 = Menlo Regular
        ]
    for path, idx in candidates:
        try:
            return ImageFont.truetype(path, size, index=idx)
        except (OSError, IOError):
            continue
    return ImageFont.load_default()


# ── Helpers ────────────────────────────────────────────────────────────────────
def round_corners(img: Image.Image, radius: int) -> Image.Image:
    """Return an RGBA copy of `img` with rounded-corner alpha mask."""
    if img.mode != "RGBA":
        img = img.convert("RGBA")
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        [(0, 0), (img.width - 1, img.height - 1)], radius=radius, fill=255
    )
    result = img.copy()
    result.putalpha(mask)
    return result


def _word_segments(headline: str, accent: str) -> list[tuple[str, str]]:
    """Tokenize headline into (word, color) segments. Accent word renders in teal."""
    return [(w, ACCENT if w == accent else TEXT_PRIMARY) for w in headline.split()]


def _draw_wrapped(
    draw: ImageDraw.ImageDraw,
    x: int,
    y: int,
    segments: list[tuple[str, str]],
    font: ImageFont.FreeTypeFont,
    max_w: int,
    line_h: int,
) -> int:
    """Greedy-wrap colored word segments into lines of width <= max_w. Returns height."""
    space_w = draw.textlength(" ", font=font)
    lines: list[list[tuple[str, str, float]]] = [[]]
    widths: list[float] = [0.0]
    for word, color in segments:
        w = draw.textlength(word, font=font)
        gap = space_w if lines[-1] else 0
        if widths[-1] + gap + w > max_w and lines[-1]:
            lines.append([])
            widths.append(0.0)
            gap = 0
        widths[-1] += gap + w
        lines[-1].append((word, color, w))

    cy = y
    for line in lines:
        cx = float(x)
        first = True
        for word, color, w in line:
            if not first:
                cx += space_w
            draw.text((cx, cy), word, fill=color, font=font)
            cx += w
            first = False
        cy += line_h
    return cy - y


# ── Compose ────────────────────────────────────────────────────────────────────
def compose(
    screenshot_path: Path,
    logo_path: Path,
    output_path: Path,
    headline: str,
    accent: str,
    subline: str,
    bullets: list[str],
    footer: str,
) -> Path:
    canvas = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(canvas)

    left_x = PAD_X

    # ── Header: icon + wordmark ──
    logo = Image.open(logo_path).convert("RGBA")
    logo = logo.resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS)
    logo = round_corners(logo, radius=int(ICON_SIZE * 0.22))
    canvas.paste(logo, (left_x, PAD_Y), logo)

    wordmark_font = load_mono(WORDMARK_SIZE, bold=True)
    wordmark_bbox = draw.textbbox((0, 0), "wrangle", font=wordmark_font)
    # Vertically align the wordmark's cap-height to the icon center.
    wordmark_y = PAD_Y + (ICON_SIZE - (wordmark_bbox[3] - wordmark_bbox[1])) // 2 - wordmark_bbox[1]
    draw.text(
        (left_x + ICON_SIZE + ICON_TEXT_GAP, wordmark_y),
        "wrangle",
        fill=TEXT_PRIMARY,
        font=wordmark_font,
    )

    # ── Headline with accent word ──
    headline_font = load_mono(HEADLINE_SIZE, bold=True)
    headline_y = PAD_Y + ICON_SIZE + HEADLINE_TOP_GAP
    headline_line_h = int(HEADLINE_SIZE * 1.2)
    headline_h = _draw_wrapped(
        draw, left_x, headline_y,
        _word_segments(headline, accent),
        headline_font, LEFT_COL_W, headline_line_h,
    )

    # ── Subline ──
    subline_font = load_mono(SUBLINE_SIZE, bold=False)
    subline_y = headline_y + headline_h + SUBLINE_TOP_GAP
    draw.text((left_x, subline_y), subline, fill=TEXT_SECONDARY, font=subline_font)

    # ── Bullets ──
    bullet_font = load_mono(BULLET_SIZE, bold=False)
    bullets_y = subline_y + SUBLINE_SIZE + BULLETS_TOP_GAP
    arrow_gap_w = draw.textlength("→  ", font=bullet_font)
    for i, b in enumerate(bullets):
        by = bullets_y + i * BULLET_LINE_H
        draw.text((left_x, by), "→", fill=ACCENT, font=bullet_font)
        draw.text((left_x + arrow_gap_w, by), b, fill=TEXT_PRIMARY, font=bullet_font)

    # ── Footer (pinned to bottom of left column) ──
    footer_font = load_mono(FOOTER_SIZE, bold=False)
    footer_bbox = draw.textbbox((0, 0), footer, font=footer_font)
    footer_h = footer_bbox[3] - footer_bbox[1]
    footer_y = H - PAD_Y - footer_h
    draw.text((left_x, footer_y), footer, fill=TEXT_TERTIARY, font=footer_font)

    # ── Screenshot (right column) ──
    right_x = PAD_X + LEFT_COL_W + COL_GAP
    content_h = H - PAD_Y * 2

    ss = Image.open(screenshot_path).convert("RGBA")
    new_w = RIGHT_COL_W
    new_h = int(ss.height * (new_w / ss.width))
    ss = ss.resize((new_w, new_h), Image.LANCZOS)
    ss = round_corners(ss, radius=SCREENSHOT_CORNER_RADIUS)
    # Center vertically; if the scaled screenshot is taller than the content area,
    # anchor the top within the padding so the bottom bleeds off-canvas (matches
    # the design where a dense overview peeks below the visible frame).
    if new_h <= content_h:
        ss_y = PAD_Y + (content_h - new_h) // 2
    else:
        ss_y = PAD_Y
    canvas.paste(ss, (right_x, ss_y), ss)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output_path, "PNG", optimize=True)
    return output_path


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Generate Wrangle's Open Graph / Twitter card preview image.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--screenshot", type=Path, default=DEFAULT_SCREENSHOT,
                        help=f"Product screenshot (default: {DEFAULT_SCREENSHOT.name})")
    parser.add_argument("--logo", type=Path, default=DEFAULT_LOGO,
                        help="Icon PNG to place next to the wordmark")
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT,
                        help="Where to write the final PNG")
    parser.add_argument("--headline", default=DEFAULT_HEADLINE)
    parser.add_argument("--accent", default=DEFAULT_ACCENT,
                        help="Word in --headline to highlight in the teal accent color (exact match)")
    parser.add_argument("--subline", default=DEFAULT_SUBLINE)
    parser.add_argument("--bullets", default=",".join(DEFAULT_BULLETS),
                        help="Comma-separated feature bullets")
    parser.add_argument("--footer", default=DEFAULT_FOOTER)

    args = parser.parse_args()

    for p in [args.screenshot, args.logo]:
        if not p.exists():
            print(f"Error: not found: {p}", file=sys.stderr)
            sys.exit(1)

    bullets = [b.strip() for b in args.bullets.split(",") if b.strip()]

    out = compose(
        args.screenshot, args.logo, args.output,
        args.headline, args.accent, args.subline, bullets, args.footer,
    )
    print(f"  {out}")
    print(f"  {W}x{H}")
    print("Done.")


if __name__ == "__main__":
    main()
