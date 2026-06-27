#!/bin/bash
WALL="$HOME/.config/hypr/.wallpaper_path"
[ -f "$WALL" ] || exit 0
IMG=$(cat "$WALL")
[ -f "$IMG" ] || exit 0

sleep 1

# Regenerate matugen colours on boot.
# The wallpaper image survives a reboot, but the generated colours do not
# always: quickshell reads ~/.cache/quickshell-colors.json, and ~/.cache can
# be cleared between sessions, leaving the shell on its fallback defaults.
# Replaying matugen here rewrites every output (quickshell, waybar, mako,
# kitty, rofi, hyprland, ...) so the theme always matches the wallpaper.
if command -v matugen &>/dev/null; then
    MODE="dark"
    SCHEME="scheme-tonal-spot"
    MODE_FILE="$HOME/.config/hypr/.wallpaper_mode"
    if [ -f "$MODE_FILE" ]; then
        read -r SAVED_MODE SAVED_SCHEME < "$MODE_FILE"
        [ -n "$SAVED_MODE" ]   && MODE="$SAVED_MODE"
        [ -n "$SAVED_SCHEME" ] && SCHEME="$SAVED_SCHEME"
    fi
    matugen image "$IMG" --prefer darkness --mode "$MODE" --type "$SCHEME" 2>/dev/null
fi

if command -v awww &>/dev/null; then
    if ! pgrep -x awww-daemon >/dev/null 2>&1; then
        setsid awww-daemon </dev/null >/dev/null 2>&1 &
        sleep 0.5
    fi
    awww img "$IMG" --transition-type none 2>/dev/null &
elif command -v swaybg &>/dev/null; then
    setsid swaybg -m fill -i "$IMG" </dev/null >/dev/null 2>&1 &
fi
