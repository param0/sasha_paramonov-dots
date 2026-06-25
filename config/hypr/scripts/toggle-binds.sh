#!/bin/bash
FLAG="/tmp/hypr-binds-disabled"

if [[ -f "$FLAG" ]]; then
    rm "$FLAG"
    cp ~/.config/hypr/keybinds.conf.bak ~/.config/hypr/keybinds.conf
    sleep 0.2
    hyprctl reload
else
    touch "$FLAG"
    cp ~/.config/hypr/keybinds.conf ~/.config/hypr/keybinds.conf.bak
    printf '# disabled\nbind = SUPER, F12, exec, bash ~/.config/hypr/scripts/toggle-binds.sh\n' \
        > ~/.config/hypr/keybinds.conf
    sleep 0.2
    hyprctl reload
fi
