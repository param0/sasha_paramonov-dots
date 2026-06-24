#!/usr/bin/env bash
sleep 1
killall -q pipewire wireplumber pipewire-pulse xdg-desktop-portal-hyprland xdg-desktop-portal

# Прокидываем переменные сессии в D-Bus
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# Поднимаем аудио/видео сервер
pipewire &
sleep 1
wireplumber &
pipewire-pulse &
sleep 2

# Поднимаем порталы для захвата экрана
/usr/lib/xdg-desktop-portal-hyprland &
sleep 2
/usr/lib/xdg-desktop-portal &
