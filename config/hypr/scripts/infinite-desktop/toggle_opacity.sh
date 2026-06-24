#!/bin/bash
if hyprctl getoption decoration:active_opacity | grep -q "1.000000"; then
    hyprctl keyword decoration:active_opacity 0.75
    hyprctl keyword decoration:inactive_opacity 0.75
else
    hyprctl keyword decoration:active_opacity 1.0
    hyprctl keyword decoration:inactive_opacity 1.0
fi
