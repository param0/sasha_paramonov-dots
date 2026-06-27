#!/usr/bin/env bash
choice=$(echo -e "⏻ Выключить\n󰜉 Перезагрузка\n󰍃 Выйти" | rofi -dmenu -i -p "Power" -theme-str 'window {width: 250px;} listview {lines: 3;}')

case "$choice" in
    *"Выключить")  ~/.config/hypr/scripts/power.sh poweroff ;;
    *"Перезагрузка") ~/.config/hypr/scripts/power.sh reboot ;;
    *"Выйти")     hyprctl dispatch exit ;;
esac
