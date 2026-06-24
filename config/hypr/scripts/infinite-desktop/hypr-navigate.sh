#!/usr/bin/env bash
DIR=$1
MODE=$(cat /tmp/hypr-desktop-mode 2>/dev/null || echo "tiling")

if [ "$MODE" = "infinite" ]; then
    echo "$DIR" > /tmp/infinite-nav
else
    case "$DIR" in
        left)  hyprctl dispatch movefocus l ;;
        right) hyprctl dispatch movefocus r ;;
        up)    hyprctl dispatch movefocus u ;;
        down)  hyprctl dispatch movefocus d ;;
    esac
fi
