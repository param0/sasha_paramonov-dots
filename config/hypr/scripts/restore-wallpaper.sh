#!/bin/bash
WALL="$HOME/.config/hypr/.wallpaper_path"
[ -f "$WALL" ] || exit 0
IMG=$(cat "$WALL")
[ -f "$IMG" ] || exit 0

sleep 1

if command -v awww &>/dev/null; then
    if ! pgrep -x awww-daemon >/dev/null 2>&1; then
        setsid awww-daemon </dev/null >/dev/null 2>&1 &
        sleep 0.5
    fi
    awww img "$IMG" --transition-type none 2>/dev/null &
elif command -v swaybg &>/dev/null; then
    setsid swaybg -m fill -i "$IMG" </dev/null >/dev/null 2>&1 &
fi
