#!/usr/bin/env bash
pkill -9 swaybg
sleep 0.5
swaybg -m fill -i "$(cat ~/.config/hypr/.bg_path 2>/dev/null)" &
