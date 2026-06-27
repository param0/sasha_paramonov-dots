#!/bin/bash
# Control Center — GNOME-style panel for Hyprland + Waybar

THEME='window { width: 380px; location: north; y-offset: 40px; border: 1px; border-color: rgba(80,80,100,0.4); border-radius: 16px; background-color: rgba(15,15,20,0.95); }
      listview { lines: 12; spacing: 2px; padding: 8px; }
      element { padding: 8px 14px; border-radius: 10px; }
      element selected { background-color: rgba(122,162,247,0.2); }
      element-text { highlight: bold; }
      inputbar { padding: 10px 14px; children: [prompt]; }
      prompt { text-color: #7aa2f7; }'

# ── State readers ──
wifi_state() {
    nmcli radio wifi 2>/dev/null | grep -q "enabled" && echo "ON" || echo "OFF"
}
bt_state() {
    bluetoothctl show 2>/dev/null | grep -q "Powered: yes" && echo "ON" || echo "OFF"
}
dnd_state() {
    makoctl mode 2>/dev/null | grep -q "do-not-disturb" && echo "ON" || echo "OFF"
}
volume_pct() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100)}'
}
volume_muted() {
    wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "MUTED" && echo "yes" || echo "no"
}
brightness_pct() {
    brightnessctl get 2>/dev/null
}
brightness_max() {
    brightnessctl max 2>/dev/null
}
battery_info() {
    cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo ""
}
notifications_count() {
    makoctl list 2>/dev/null | grep -c "^Notification" 2>/dev/null || echo "0"
}

# ── Build menu ──
build_menu() {
    local wifi=$(wifi_state)
    local bt=$(bt_state)
    local dnd=$(dnd_state)
    local vol=$(volume_pct)
    local muted=$(volume_muted)
    local bright=$(brightness_pct)
    local bright_max=$(brightness_max)
    local bat=$(battery_info)
    local notif_count=$(notifications_count)

    local wifi_icon="󰤟"; [ "$wifi" = "ON" ] && wifi_icon="󰤨"
    local wifi_label="Wi-Fi"; [ "$wifi" = "ON" ] && wifi_label="Wi-Fi — вкл" || wifi_label="Wi-Fi — выкл"

    local bt_icon="󰂯"; [ "$bt" = "ON" ] && bt_icon="󰂱"
    local bt_label="Bluetooth"; [ "$bt" = "ON" ] && bt_label="Bluetooth — вкл" || bt_label="Bluetooth — выкл"

    local dnd_icon="󰂛"; [ "$dnd" = "ON" ] && dnd_icon="󰂚"
    local dnd_label="Не беспокоить"; [ "$dnd" = "ON" ] && dnd_label="Не беспокоить — вкл" || dnd_label="Не беспокоить — выкл"

    local vol_icon=""; [ "$muted" = "yes" ] && vol_icon="" || { [ "$vol" -gt 50 ] && vol_icon="" || vol_icon=""; }
    local vol_label="Громкость: ${vol}%"; [ "$muted" = "yes" ] && vol_label="Громкость: выкл"

    local bright_pct=0
    [ -n "$bright" ] && [ -n "$bright_max" ] && [ "$bright_max" -gt 0 ] && bright_pct=$((bright * 100 / bright_max))
    local bright_label="Яркость: ${bright_pct}%"

    local bat_label=""
    [ -n "$bat" ] && {
        local bat_icon=""; [ "$bat" -gt 80 ] && bat_icon="" || { [ "$bat" -gt 60 ] && bat_icon="" || { [ "$bat" -gt 40 ] && bat_icon="" || { [ "$bat" -gt 20 ] && bat_icon="" || bat_icon=""; }; }; }
        bat_label="${bat_icon} Батарея: ${bat}%"
    }

    local notif_label="󰂚 Уведомления"
    [ "$notif_count" -gt 0 ] && notif_label=" Уведомления (${notif_count})"

    cat << EOF
${wifi_icon}  ${wifi_label}
${bt_icon}  ${bt_label}
${dnd_icon}  ${dnd_label}
${vol_icon}  ${vol_label}
  ${bright_label}
${bat_label:+${bat_label}
}──────────────────────
${notif_label}
󰎟  Очистить все уведомления
  Восстановить последние
──────────────────────
  Скриншот (выделение)
  Скриншот (экран)
──────────────────────
  Заблокировать
  Выход
  Перезагрузка
  Выключение
EOF
}

# ── Handle selection ──
handle() {
    local choice="$1"

    case "$choice" in
        *"Wi-Fi"*)
            if [ "$(wifi_state)" = "ON" ]; then
                nmcli radio wifi off
                notify-send "Wi-Fi" "Выключен"
            else
                nmcli radio wifi on
                notify-send "Wi-Fi" "Включен"
            fi
            ;;
        *"Bluetooth"*)
            if [ "$(bt_state)" = "ON" ]; then
                bluetoothctl power off
                notify-send "Bluetooth" "Выключен"
            else
                bluetoothctl power on
                notify-send "Bluetooth" "Включен"
            fi
            ;;
        *"Не беспокоить"*)
            makoctl mode -t do-not-disturb
            if [ "$(dnd_state)" = "ON" ]; then
                notify-send "DND" "Включен"
            else
                notify-send "DND" "Выключен"
            fi
            ;;
        *"Громкость"*)
            # Toggle mute on click
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
            ;;
        *"Яркость"*)
            # Cycle brightness: 25% → 50% → 75% → 100%
            local max=$(brightnessctl max 2>/dev/null)
            local cur=$(brightnessctl get 2>/dev/null)
            local pct=$((cur * 100 / max))
            local new_pct=25
            [ "$pct" -lt 50 ] && new_pct=50
            [ "$pct" -ge 50 ] && [ "$pct" -lt 75 ] && new_pct=75
            [ "$pct" -ge 75 ] && new_pct=100
            brightnessctl set "${new_pct}%"
            notify-send "Яркость" "${new_pct}%"
            ;;
        *"Уведомления"*)
            bash ~/.config/hypr/scripts/notifications.sh
            ;;
        *"Очистить все"*)
            makoctl dismiss --all
            notify-send "Уведомления" "Все очищены"
            ;;
        *"Восстановить"*)
            makoctl restore
            ;;
        *"выделение"*)
            hyprshot -m region
            ;;
        *"экран"*)
            hyprshot -m output
            ;;
        *"Заблокировать"*)
            hyprlock
            ;;
        *"Выход"*)
            hyprctl dispatch exit
            ;;
        *"Перезагрузка"*)
            systemctl reboot 2>/dev/null || reboot
            ;;
        *"Выключение"*)
            systemctl poweroff 2>/dev/null || poweroff
            ;;
    esac
}

# ── Main ──
SELECTED=$(build_menu | rofi -dmenu -i -p " Панель управления" -theme-str "$THEME" 2>/dev/null)

if [ -n "$SELECTED" ]; then
    handle "$SELECTED"
fi
