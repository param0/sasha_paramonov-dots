#!/usr/bin/env bash
sleep 1

# На runit/Artix XDG_RUNTIME_DIR может не задаться для процессов сессии. Если
# PipeWire стартует без него (или с другим), его сокет оказывается там, где
# клиенты (wpctl, приложения) его не находят → "Could not connect to PipeWire"
# и нет звука. Жёстко выставляем стандартный путь, чтобы сервер и клиенты
# смотрели в одно место.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null

killall -q pipewire wireplumber pipewire-pulse xdg-desktop-portal-hyprland xdg-desktop-portal

# Прокидываем переменные сессии в D-Bus.
# --all, а не --systemd: на runit/Artix нет systemd, иначе порталы получают
# пустой XDG_CURRENT_DESKTOP и захват экрана в OBS не работает.
dbus-update-activation-environment --all WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_RUNTIME_DIR

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
