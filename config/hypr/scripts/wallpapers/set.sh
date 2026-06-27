#!/bin/bash
WALL="$1"
[ -f "$WALL" ] || exit 1

echo "$WALL" > "$HOME/.config/hypr/.wallpaper_path"
echo "$WALL" > "$HOME/.config/hypr/.bg_path"

# Detect wallpaper brightness and saturation
MODE="dark"
SCHEME="scheme-tonal-spot"
if command -v convert &>/dev/null; then
    # Get brightness (0-100%)
    BRIGHTNESS=$(convert "$WALL" -resize 1x1 -colorspace Gray txt:- 2>/dev/null | tail -1 | grep -oP '\d+\.\d+(?=%)')
    # Get saturation from HSL tuple (0-255 scale, second value)
    SAT_RAW=$(convert "$WALL" -resize 1x1 -colorspace HSL txt:- 2>/dev/null | tail -1 | grep -oP '\d+(?=,\d+\))' | head -1)
    if [ -n "$SAT_RAW" ]; then
        [ "$SAT_RAW" -lt 10 ] && SCHEME="scheme-monochrome"
    fi
    # If wallpaper is achromatic (grey/black/white), use monochrome
    if [ -n "$SATURATION" ]; then
        [ "$SATURATION" -lt 5 ] && SCHEME="scheme-monochrome"
    fi
fi

# Update all matugen templates to match mode
TMPL_DIR="$HOME/.config/matugen/templates"
if [ "$MODE" = "light" ]; then
    find "$TMPL_DIR" -type f -exec sed -i 's/\.dark\./.light./g' {} +
else
    find "$TMPL_DIR" -type f -exec sed -i 's/\.light\./.dark./g' {} +
fi

# Generate colors
if command -v matugen &>/dev/null; then
    matugen image "$WALL" --prefer darkness --mode "$MODE" --type "$SCHEME" 2>/dev/null
fi

pkill -9 swaybg 2>/dev/null

if ! pgrep -x awww-daemon >/dev/null 2>&1; then
    setsid awww-daemon </dev/null >/dev/null 2>&1 &
    sleep 0.5
fi

if command -v awww &>/dev/null; then
    awww img "$WALL" --transition-type wave --transition-step 90 --transition-duration 1.2 --transition-fps 60 </dev/null >/dev/null 2>&1
elif command -v swaybg &>/dev/null; then
    pkill -9 swaybg 2>/dev/null
    setsid swaybg -m fill -i "$WALL" </dev/null >/dev/null 2>&1 &
fi

exit 0
