#!/usr/bin/env bash
pkill -9 swaybg 2>/dev/null
pkill -9 swww 2>/dev/null
sleep 0.3
BG=$(cat "$HOME/.config/hypr/.bg_path" 2>/dev/null | sed "s|~|$HOME|g")
[ -f "$BG" ] || BG="$HOME/Pictures/Wallpapers/darkARTIX.png"
[ -f "$BG" ] || exit 0

if command -v swww &>/dev/null; then
    setsid swww-daemon </dev/null >/dev/null 2>&1 &
    sleep 0.3
    setsid swww img "$BG" </dev/null >/dev/null 2>&1 &
else
    setsid swaybg -m fill -i "$BG" </dev/null >/dev/null 2>&1 &
fi
