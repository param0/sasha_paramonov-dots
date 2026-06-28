#!/usr/bin/env bash
# Поднимает PipeWire + порталы при входе. Делает это устойчиво на runit/Artix,
# где после перезагрузки звук (PulseAudio/PipeWire) и захват экрана в OBS
# регулярно «слетали».
sleep 1

# XDG_RUNTIME_DIR — критично: сервер PipeWire и клиенты (wpctl, OBS, приложения)
# должны смотреть в ОДИН сокет, иначе "Could not connect to PipeWire" и тишина.
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
# ждём, пока elogind создаст /run/user/UID (до ~5 c)
for _ in $(seq 1 10); do [ -d "$XDG_RUNTIME_DIR" ] && break; sleep 0.5; done
[ -d "$XDG_RUNTIME_DIR" ] || mkdir -p "$XDG_RUNTIME_DIR" 2>/dev/null

killall -q pipewire wireplumber pipewire-pulse xdg-desktop-portal-hyprland xdg-desktop-portal
sleep 0.5

# Прокидываем переменные сессии в D-Bus.
# --all, а не --systemd: на runit/Artix нет systemd, иначе порталы получают
# пустой XDG_CURRENT_DESKTOP и захват экрана в OBS не работает.
dbus-update-activation-environment --all \
    WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_RUNTIME_DIR 2>/dev/null

# Аудио/видео сервер (setsid — чтобы пережили завершение этого скрипта)
setsid pipewire        >/dev/null 2>&1 &
sleep 1
setsid wireplumber     >/dev/null 2>&1 &
setsid pipewire-pulse  >/dev/null 2>&1 &
sleep 2

# Снимаем mute со стандартного вывода — после сброса дефолт иногда приходит
# заглушённым (например, когда BT-наушники не подключены).
command -v wpctl >/dev/null 2>&1 && wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null

# Порталы для захвата экрана (OBS «Захват экрана (PipeWire)»)
setsid /usr/lib/xdg-desktop-portal-hyprland >/dev/null 2>&1 &
sleep 2
setsid /usr/lib/xdg-desktop-portal >/dev/null 2>&1 &
