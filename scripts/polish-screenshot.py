#!/usr/bin/env python3
"""
polish-screenshot.py — Post-process raw Wrangle screenshots into polished marketing images.

Takes raw `screencapture` PNGs and outputs images with:
- Rounded corner masking
- Transparent corners (PNG) for clean compositing
- Optional notification banner overlay

Usage:
    python3 scripts/polish-screenshot.py <input> <output> [options]

Options:
    --radius N                     Corner radius in px (default: 20)
    --notification                 Add macOS notification banner overlay
    --notification-title TEXT      Notification title (default: Wrangle)
    --notification-body TEXT       Notification body text
    --notification-icon PATH       Icon PNG (default: auto-detect from Assets)
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Error: Pillow is required. Install with: pip3 install Pillow", file=sys.stderr)
    sys.exit(1)


def round_corners(img: Image.Image, radius: int) -> Image.Image:
    """Apply rounded corner mask to an image, returning RGBA with transparent corners."""
    if img.mode != "RGBA":
        img = img.convert("RGBA")

    mask = Image.new("L", img.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (img.width - 1, img.height - 1)], radius=radius, fill=255)

    result = img.copy()
    result.putalpha(mask)
    return result


def _load_sf_font(bold: bool, size: int) -> ImageFont.FreeTypeFont | None:
    """Try to load SF Pro font, returning None on failure."""
    if bold:
        candidates = [
            "/System/Library/Fonts/SFNS.ttf",
            "/Library/Fonts/SF-Pro-Text-Bold.otf",
            "/Library/Fonts/SF-Pro-Display-Bold.otf",
        ]
    else:
        candidates = [
            "/System/Library/Fonts/SFNS.ttf",
            "/Library/Fonts/SF-Pro-Text-Regular.otf",
            "/Library/Fonts/SF-Pro-Display-Regular.otf",
        ]
    for path in candidates:
        try:
            return ImageFont.truetype(path, size)
        except (OSError, IOError):
            continue
    for path in ["/System/Library/Fonts/Helvetica.ttc", "/System/Library/Fonts/HelveticaNeue.ttc"]:
        try:
            return ImageFont.truetype(path, size)
        except (OSError, IOError):
            continue
    return None


def draw_notification(
    canvas: Image.Image,
    title: str = "Wrangle",
    body: str = "",
    icon_path: str | None = None,
) -> None:
    """Draw a macOS Sequoia-style notification banner on the canvas."""
    cw = canvas.width
    sf = cw / 2560.0  # scale factor relative to @2x baseline

    banner_w = int(720 * sf)
    banner_h = int(128 * sf)
    radius = int(32 * sf)
    top_offset = int(16 * sf)
    icon_size = int(64 * sf)
    padding_x = int(20 * sf)
    text_gap = int(12 * sf)

    title_font_size = max(12, int(26 * sf))
    body_font_size = max(12, int(26 * sf))

    title_font = _load_sf_font(bold=True, size=title_font_size) or ImageFont.load_default()
    body_font = _load_sf_font(bold=False, size=body_font_size) or ImageFont.load_default()

    banner = Image.new("RGBA", (banner_w, banner_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(banner)

    draw.rounded_rectangle(
        [(0, 0), (banner_w - 1, banner_h - 1)],
        radius=radius,
        fill=(40, 40, 44, 200),
    )
    draw.rounded_rectangle(
        [(0, 0), (banner_w - 1, banner_h - 1)],
        radius=radius,
        outline=(255, 255, 255, 25),
        width=max(1, int(sf)),
    )

    icon_x = padding_x
    icon_y = (banner_h - icon_size) // 2
    if icon_path and Path(icon_path).exists():
        try:
            icon = Image.open(icon_path).convert("RGBA")
            icon = icon.resize((icon_size, icon_size), Image.LANCZOS)
            icon_r = int(icon_size * 0.22)
            icon_mask = Image.new("L", (icon_size, icon_size), 0)
            ImageDraw.Draw(icon_mask).rounded_rectangle(
                [(0, 0), (icon_size - 1, icon_size - 1)], radius=icon_r, fill=255
            )
            icon.putalpha(icon_mask)
            banner.alpha_composite(icon, (icon_x, icon_y))
        except Exception:
            pass

    text_x = icon_x + icon_size + text_gap
    max_text_w = banner_w - text_x - padding_x

    title_y = icon_y + int(4 * sf)
    title_draw = ImageDraw.Draw(banner)
    display_title = title
    bbox = title_draw.textbbox((0, 0), display_title, font=title_font)
    while bbox[2] - bbox[0] > max_text_w and len(display_title) > 5:
        display_title = display_title[:-2] + "\u2026"
        bbox = title_draw.textbbox((0, 0), display_title, font=title_font)
    title_draw.text((text_x, title_y), display_title, fill=(255, 255, 255, 242), font=title_font)

    if body:
        title_h = bbox[3] - bbox[1]
        body_y = title_y + title_h + int(4 * sf)
        display_body = body
        bbox_b = title_draw.textbbox((0, 0), display_body, font=body_font)
        while bbox_b[2] - bbox_b[0] > max_text_w and len(display_body) > 5:
            display_body = display_body[:-2] + "\u2026"
            bbox_b = title_draw.textbbox((0, 0), display_body, font=body_font)
        title_draw.text((text_x, body_y), display_body, fill=(255, 255, 255, 166), font=body_font)

    banner_x = (cw - banner_w) // 2
    canvas.alpha_composite(banner, (banner_x, top_offset))


def polish_screenshot(
    input_path: str,
    output_path: str,
    corner_radius: int = 24,
    notification: bool = False,
    notification_title: str = "Wrangle",
    notification_body: str = "",
    notification_icon: str | None = None,
):
    """Process a single screenshot. Output is same dimensions as input."""
    src = Image.open(input_path).convert("RGBA")

    # Round corners (no resizing)
    result = round_corners(src, corner_radius)

    # Add notification banner if requested
    if notification:
        icon = notification_icon
        if icon is None:
            script_dir = Path(__file__).resolve().parent
            project_dir = script_dir.parent
            default_icon = project_dir / "Wrangle" / "Assets.xcassets" / "AppIcon.appiconset" / "icon_128.png"
            if default_icon.exists():
                icon = str(default_icon)
        draw_notification(result, notification_title, notification_body, icon)

    # Save as PNG (keep RGBA for transparent corners)
    result.save(output_path, "PNG", optimize=True)

    return output_path


def main():
    parser = argparse.ArgumentParser(
        description="Polish Wrangle screenshots for marketing use.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("input", help="Path to raw screenshot PNG")
    parser.add_argument("output", help="Output path for polished image")
    parser.add_argument("--radius", type=int, default=24, help="Corner radius in px (default: 24)")
    parser.add_argument("--notification", action="store_true", help="Add macOS notification banner overlay")
    parser.add_argument("--notification-title", default="Wrangle", help="Notification title (default: Wrangle)")
    parser.add_argument("--notification-body", default="", help="Notification body text")
    parser.add_argument("--notification-icon", default=None, help="Path to notification icon PNG (default: auto-detect)")

    args = parser.parse_args()

    if not Path(args.input).exists():
        print(f"Error: Input file not found: {args.input}", file=sys.stderr)
        sys.exit(1)

    Path(args.output).parent.mkdir(parents=True, exist_ok=True)

    result = polish_screenshot(
        args.input, args.output, args.radius,
        args.notification, args.notification_title,
        args.notification_body, args.notification_icon,
    )
    print(f"  {result}")
    print("Done.")


if __name__ == "__main__":
    main()
