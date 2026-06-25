#!/usr/bin/env bash
[[ -z "$1" ]] && exit 1
realpath "$1" > ~/.config/hypr/.bg_path
~/.config/hypr/scripts/start_bg.sh
