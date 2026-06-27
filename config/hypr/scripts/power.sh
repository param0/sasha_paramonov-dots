#!/usr/bin/env bash
case "$1" in
    poweroff)
        loginctl poweroff
        ;;
    reboot)
        loginctl reboot
        ;;
esac
