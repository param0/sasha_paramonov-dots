#!/usr/bin/env bash
# Прокидывает переменные сессии в D-Bus и поднимает порталы (захват экрана / OBS)
# и PipeWire — БЕЗ хаков: XDG_RUNTIME_DIR даёт elogind, мы его не трогаем и не
# пересоздаём. Демоны стартуют только если ещё не запущены (никаких killall),
# чтобы не драться с сервисами/правильной инициализацией.
sleep 1

dbus-update-activation-environment --all \
    WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE 2>/dev/null

# Аудио (PipeWire). Стартуем мягко, только если не запущено.
pgrep -x pipewire       >/dev/null 2>&1 || pipewire &
pgrep -x wireplumber    >/dev/null 2>&1 || wireplumber &
pgrep -x pipewire-pulse >/dev/null 2>&1 || pipewire-pulse &
sleep 1

# Порталы для захвата экрана (OBS «Захват экрана (PipeWire)»)
pgrep -f xdg-desktop-portal-hyprland >/dev/null 2>&1 || /usr/lib/xdg-desktop-portal-hyprland &
sleep 1
pgrep -f 'xdg-desktop-portal$'       >/dev/null 2>&1 || /usr/lib/xdg-desktop-portal &
