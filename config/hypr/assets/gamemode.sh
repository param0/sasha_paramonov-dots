#!/usr/bin/env sh

HYPRGAMEMODE=$(hyprctl getoption animations:enabled | awk 'NR==1{print $2}')

# ID fixo para substituir sempre a mesma notificação
RID=7777  

if [ "$HYPRGAMEMODE" = 1 ] ; then
    hyprctl --batch "\
keyword animations:enabled 0;\
keyword animation borderangle,0;\
keyword decoration:shadow:enabled 0;\
keyword decoration:blur:enabled 0;\
keyword decoration:fullscreen_opacity 1;\
keyword general:gaps_in 0;\
keyword general:gaps_out 0;\
keyword general:border_size 1;\
keyword decoration:rounding 0"

    dunstify -r "$RID" -u normal -a "GamemodeON" \
    --icon=$HOME/.config/dunst/gamemodeON.png \
    "Gamemode [ON]" "Modo de desempenho ativado."

else
dunstify -r "$RID" -u normal -a "GamemodeOFF" \
    --icon=$HOME/.config/dunst/gamemodeOFF.png \
    "Gamemode [OFF]" "Modo de desempenho desativado."

    hyprctl reload
fi
