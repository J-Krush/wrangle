#!/bin/bash
set -euo pipefail

# polish-video.sh — Post-process raw Wrangle screen recordings into polished MP4 + GIF.
#
# Takes raw .mov files (from `screencapture -v -l <windowID>`) and produces
# polished videos with gradient background, rounded corners, and drop shadow —
# matching the visual treatment from polish-screenshot.py.
#
# Usage:
#   ./scripts/polish-video.sh <input.mov> <output-basename> [options]
#
# Options:
#   --size hero|blog|social|all    Canvas size preset (default: hero)
#   --gradient dark|subtle|deep    Gradient style (default: dark)
#   --format mp4|gif|both          Output format (default: both)
#   --radius N                     Corner radius in px (default: 20)
#   --fps N                        GIF framerate (default: 15)
#   --no-shadow                    Disable drop shadow
#   --quality N                    H.264 CRF, 0-51 (default: 18)
#
# Prerequisites:
#   brew install ffmpeg
#   pip3 install Pillow

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Defaults ---
SIZE="hero"
GRADIENT="dark"
FORMAT="both"
RADIUS=20
GIF_FPS=15
SHADOW=true
CRF=18

# --- Parse arguments ---
INPUT=""
OUTPUT_BASE=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --size)     SIZE="$2"; shift 2 ;;
        --gradient) GRADIENT="$2"; shift 2 ;;
        --format)   FORMAT="$2"; shift 2 ;;
        --radius)   RADIUS="$2"; shift 2 ;;
        --fps)      GIF_FPS="$2"; shift 2 ;;
        --no-shadow) SHADOW=false; shift ;;
        --quality)  CRF="$2"; shift 2 ;;
        -h|--help)
            sed -n '3,/^$/p' "$0" | sed 's/^# \?//'
            exit 0
            ;;
        *)
            if [[ -z "$INPUT" ]]; then
                INPUT="$1"
            elif [[ -z "$OUTPUT_BASE" ]]; then
                OUTPUT_BASE="$1"
            else
                echo "Error: Unexpected argument: $1" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [[ -z "$INPUT" || -z "$OUTPUT_BASE" ]]; then
    echo "Usage: $0 <input.mov> <output-basename> [options]" >&2
    exit 1
fi

if [[ ! -f "$INPUT" ]]; then
    echo "Error: Input file not found: $INPUT" >&2
    exit 1
fi

if ! command -v ffmpeg &>/dev/null; then
    echo "Error: ffmpeg is required. Install with: brew install ffmpeg" >&2
    exit 1
fi

if ! python3 -c "from PIL import Image" &>/dev/null; then
    echo "Error: Pillow is required. Install with: pip3 install Pillow" >&2
    exit 1
fi

# --- Size presets (width x height) ---
get_canvas_size() {
    case "$1" in
        hero)   echo "2560 1600" ;;
        blog)   echo "1920 1200" ;;
        social) echo "1280 800" ;;
        *) echo "Error: Unknown size: $1" >&2; exit 1 ;;
    esac
}

# --- Gradient presets (top_r,top_g,top_b bottom_r,bottom_g,bottom_b) ---
get_gradient() {
    case "$1" in
        dark)   echo "13,13,13 26,26,46" ;;
        subtle) echo "18,18,18 22,22,34" ;;
        deep)   echo "8,8,12 30,20,50" ;;
        *) echo "Error: Unknown gradient: $1" >&2; exit 1 ;;
    esac
}

# --- Temporary files with cleanup ---
TMPDIR_WORK="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_WORK"' EXIT

# --- Generate assets via Python/Pillow ---
generate_assets() {
    local canvas_w="$1" canvas_h="$2" video_w="$3" video_h="$4"
    local gradient_top="$5" gradient_bot="$6" radius="$7" shadow_enabled="$8"

    python3 - "$canvas_w" "$canvas_h" "$video_w" "$video_h" \
        "$gradient_top" "$gradient_bot" "$radius" "$shadow_enabled" \
        "$TMPDIR_WORK" <<'PYEOF'
import sys
from PIL import Image, ImageDraw, ImageFilter

canvas_w, canvas_h = int(sys.argv[1]), int(sys.argv[2])
video_w, video_h = int(sys.argv[3]), int(sys.argv[4])
top_rgb = tuple(int(c) for c in sys.argv[5].split(","))
bot_rgb = tuple(int(c) for c in sys.argv[6].split(","))
radius = int(sys.argv[7])
shadow_enabled = sys.argv[8] == "true"
tmpdir = sys.argv[9]

# Gradient background
gradient = Image.new("RGB", (canvas_w, canvas_h))
pixels = gradient.load()
for y in range(canvas_h):
    t = y / max(canvas_h - 1, 1)
    r = int(top_rgb[0] + (bot_rgb[0] - top_rgb[0]) * t)
    g = int(top_rgb[1] + (bot_rgb[1] - top_rgb[1]) * t)
    b = int(top_rgb[2] + (bot_rgb[2] - top_rgb[2]) * t)
    for x in range(canvas_w):
        pixels[x, y] = (r, g, b)
gradient.save(f"{tmpdir}/gradient.png")

# Rounded rectangle mask (white on black, used for alphamerge)
mask = Image.new("L", (video_w, video_h), 0)
draw = ImageDraw.Draw(mask)
draw.rounded_rectangle([(0, 0), (video_w - 1, video_h - 1)], radius=radius, fill=255)
# Convert to RGB for ffmpeg (alphamerge uses luma)
mask_rgb = Image.new("RGB", (video_w, video_h), (0, 0, 0))
mask_rgb.paste(Image.merge("RGB", (mask, mask, mask)))
mask_rgb.save(f"{tmpdir}/mask.png")

# Drop shadow
if shadow_enabled:
    blur = 80
    offset_y = 16
    spread = blur * 2
    shadow_w = video_w + spread * 2
    shadow_h = video_h + spread * 2

    shadow_alpha = Image.new("L", (shadow_w, shadow_h), 0)
    shadow_alpha.paste(mask, (spread, spread + offset_y))
    shadow_alpha = shadow_alpha.filter(ImageFilter.GaussianBlur(radius=blur // 2))
    shadow_alpha = shadow_alpha.point(lambda p: int(p * 0.5))

    black = Image.new("RGB", (shadow_w, shadow_h), (0, 0, 0))
    shadow = Image.merge("RGBA", (*black.split(), shadow_alpha))
    shadow.save(f"{tmpdir}/shadow.png")

    # Also save a pre-composited gradient + shadow for simpler ffmpeg filter
    bg = gradient.convert("RGBA")
    shadow_x = (canvas_w - shadow_w) // 2
    shadow_y = (canvas_h - shadow_h) // 2
    bg.alpha_composite(shadow, (shadow_x, shadow_y))
    bg.convert("RGB").save(f"{tmpdir}/bg_shadow.png")
else:
    # No shadow — just use gradient as background
    gradient.save(f"{tmpdir}/bg_shadow.png")

print("Assets generated.")
PYEOF
}

# --- Process a single size ---
process_size() {
    local size_name="$1"
    local canvas_dims
    canvas_dims=$(get_canvas_size "$size_name")
    local canvas_w canvas_h
    canvas_w=$(echo "$canvas_dims" | cut -d' ' -f1)
    canvas_h=$(echo "$canvas_dims" | cut -d' ' -f2)

    local gradient_vals
    gradient_vals=$(get_gradient "$GRADIENT")
    local gradient_top gradient_bot
    gradient_top=$(echo "$gradient_vals" | cut -d' ' -f1)
    gradient_bot=$(echo "$gradient_vals" | cut -d' ' -f2)

    # Get input video dimensions
    local src_w src_h
    src_w=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$INPUT")
    src_h=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$INPUT")

    # Calculate scaled video size (8% horizontal padding, 6% vertical)
    local pad_x pad_y max_w max_h
    pad_x=$((canvas_w * 8 / 100))
    pad_y=$((canvas_h * 6 / 100))
    max_w=$((canvas_w - pad_x * 2))
    max_h=$((canvas_h - pad_y * 2))

    # Scale maintaining aspect ratio
    local scale_w scale_h scale video_w video_h
    # Use bc for floating point, pick the smaller scale
    scale=$(python3 -c "
sw = $max_w / $src_w
sh = $max_h / $src_h
print(min(sw, sh))
")
    video_w=$(python3 -c "print(int($src_w * $scale) // 2 * 2)")  # ensure even
    video_h=$(python3 -c "print(int($src_h * $scale) // 2 * 2)")

    # Scale radius proportionally
    local scaled_radius
    scaled_radius=$(python3 -c "print(max(1, int($RADIUS * $scale)))")

    echo "  Canvas: ${canvas_w}x${canvas_h}, Video: ${video_w}x${video_h}, Radius: ${scaled_radius}"

    # Generate gradient, mask, shadow PNGs
    generate_assets "$canvas_w" "$canvas_h" "$video_w" "$video_h" \
        "$gradient_top" "$gradient_bot" "$scaled_radius" "$SHADOW"

    # Calculate overlay position (centered)
    local overlay_x overlay_y
    overlay_x=$(( (canvas_w - video_w) / 2 ))
    overlay_y=$(( (canvas_h - video_h) / 2 ))

    local suffix=""
    if [[ "$SIZE" == "all" ]]; then
        suffix="-${size_name}"
    fi

    # --- MP4 output ---
    if [[ "$FORMAT" == "mp4" || "$FORMAT" == "both" ]]; then
        local mp4_out="${OUTPUT_BASE}${suffix}.mp4"
        mkdir -p "$(dirname "$mp4_out")"
        echo "  Encoding MP4: $mp4_out"

        ffmpeg -y -hide_banner -loglevel warning \
            -loop 1 -i "$TMPDIR_WORK/bg_shadow.png" \
            -i "$INPUT" \
            -loop 1 -i "$TMPDIR_WORK/mask.png" \
            -filter_complex "
                [1:v] scale=${video_w}:${video_h}:flags=lanczos, format=rgba [scaled];
                [2:v] format=gray, scale=${video_w}:${video_h} [mask_scaled];
                [scaled][mask_scaled] alphamerge [rounded];
                [0:v] scale=${canvas_w}:${canvas_h} [bg];
                [bg][rounded] overlay=x=${overlay_x}:y=${overlay_y}:shortest=1 [out]
            " \
            -map "[out]" \
            -c:v libx264 -crf "$CRF" -preset slow \
            -pix_fmt yuv420p \
            -movflags +faststart \
            -t "$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$INPUT")" \
            "$mp4_out"

        local mp4_size
        mp4_size=$(du -h "$mp4_out" | cut -f1)
        echo "  MP4 done: $mp4_out ($mp4_size)"
    fi

    # --- GIF output (two-pass palette optimization) ---
    if [[ "$FORMAT" == "gif" || "$FORMAT" == "both" ]]; then
        local gif_out="${OUTPUT_BASE}${suffix}.gif"
        mkdir -p "$(dirname "$gif_out")"
        echo "  Encoding GIF: $gif_out (fps=$GIF_FPS)"

        local palette="$TMPDIR_WORK/palette.png"

        # Pass 1: Generate optimized palette
        ffmpeg -y -hide_banner -loglevel warning \
            -loop 1 -i "$TMPDIR_WORK/bg_shadow.png" \
            -i "$INPUT" \
            -loop 1 -i "$TMPDIR_WORK/mask.png" \
            -filter_complex "
                [1:v] scale=${video_w}:${video_h}:flags=lanczos, format=rgba [scaled];
                [2:v] format=gray, scale=${video_w}:${video_h} [mask_scaled];
                [scaled][mask_scaled] alphamerge [rounded];
                [0:v] scale=${canvas_w}:${canvas_h} [bg];
                [bg][rounded] overlay=x=${overlay_x}:y=${overlay_y}:shortest=1,
                fps=${GIF_FPS} [togif];
                [togif] palettegen=stats_mode=diff [palette]
            " \
            -map "[palette]" \
            -t "$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$INPUT")" \
            "$palette"

        # Pass 2: Encode GIF with palette
        ffmpeg -y -hide_banner -loglevel warning \
            -loop 1 -i "$TMPDIR_WORK/bg_shadow.png" \
            -i "$INPUT" \
            -loop 1 -i "$TMPDIR_WORK/mask.png" \
            -i "$palette" \
            -filter_complex "
                [1:v] scale=${video_w}:${video_h}:flags=lanczos, format=rgba [scaled];
                [2:v] format=gray, scale=${video_w}:${video_h} [mask_scaled];
                [scaled][mask_scaled] alphamerge [rounded];
                [0:v] scale=${canvas_w}:${canvas_h} [bg];
                [bg][rounded] overlay=x=${overlay_x}:y=${overlay_y}:shortest=1,
                fps=${GIF_FPS} [togif];
                [togif][3:v] paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle [out]
            " \
            -map "[out]" \
            -t "$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$INPUT")" \
            "$gif_out"

        local gif_size
        gif_size=$(du -h "$gif_out" | cut -f1)
        echo "  GIF done: $gif_out ($gif_size)"
    fi
}

# --- Main ---
echo "==> Polishing video: $(basename "$INPUT")"
echo "    Size: $SIZE | Gradient: $GRADIENT | Format: $FORMAT | Radius: $RADIUS"

if [[ "$SIZE" == "all" ]]; then
    for s in hero blog social; do
        echo ""
        echo "--- $s ---"
        process_size "$s"
    done
else
    process_size "$SIZE"
fi

echo ""
echo "Done."
