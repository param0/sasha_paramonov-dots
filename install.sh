#!/usr/bin/env bash

[[ $EUID -eq 0 ]] && echo "Запускай без sudo." && exit 1

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTS_VERSION="1.3"
DOTS_VER_FILE="$HOME/.config/dots_version"

sudo pacman -Sy --noconfirm --needed libnewt git base-devel rsync

export NEWT_COLORS="
root=,black
window=,black
border=lightgray,black
textbox=lightgray,black
button=black,lightgray
actbutton=black,cyan
listbox=lightgray,black
actlistbox=black,cyan
actsellistbox=black,cyan
title=cyan,black
"

PKGS=(
    hyprland alacritty waybar rofi thunar swaybg fastfetch btop micro
    cliphist wl-clipboard pipewire pipewire-pulse pipewire-alsa wireplumber
    brightnessctl ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji
    qt5ct qt6ct kvantum pamixer pavucontrol mako nwg-look quickshell
    cava zsh zsh-autosuggestions zsh-syntax-highlighting wget curl rsync
    hyprcursor hypridle hyprpaper hyprshot
)

AUR_PKGS=(
    matugen-bin qogir-cursor-theme python-pywal16
    hyprlauncher hyprtoolkit hyprwire
)

check_system() {
    clear
    echo "=== Статус системы ==="
    [[ -f "$DOTS_VER_FILE" ]] && CURRENT_VER=$(cat "$DOTS_VER_FILE") || CURRENT_VER="Не установлены"
    echo "Версия dots: Текущая [$CURRENT_VER] | В скрипте [$DOTS_VERSION]"
    echo "------------------------"
    
    command -v yay &> /dev/null && echo "[+] yay: установлен" || echo "[-] yay: отсутствует"
    
    for pkg in hyprland waybar alacritty swaybg zsh; do
        if pacman -Qs "^$pkg$" &> /dev/null; then
            echo "[+] $pkg: установлен"
        else
            echo "[-] $pkg: отсутствует"
        fi
    done
    echo "------------------------"
    read -n 1 -s -r -p "Нажми любую клавишу..."
}

install_yay() {
    if ! command -v yay &> /dev/null; then
        git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
        cd /tmp/yay-bin
        makepkg -si --noconfirm
        cd - > /dev/null
        rm -rf /tmp/yay-bin
    fi
}

install_pkgs() {
    install_yay
    sudo pacman -S --needed --noconfirm "${PKGS[@]}"
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"
}

apply_dots() {
    mkdir -p ~/.config ~/Pictures/Wallpapers
    
    if [[ -d "$DIR/config" ]]; then
        rsync -a "$DIR/config/" ~/.config/
    fi
    
    [[ -f "$DIR/.zshrc" ]] && cp "$DIR/.zshrc" ~/
    [[ -f "$DIR/.bashrc" ]] && cp "$DIR/.bashrc" ~/
    [[ -f "$DIR/darkARTIX.png" ]] && cp "$DIR/darkARTIX.png" ~/Pictures/Wallpapers/
    
    find ~/.config/hypr/scripts -type f -name "*.sh" -exec chmod +x {} \; 2>/dev/null
    
    echo "$DOTS_VERSION" > "$DOTS_VER_FILE"
    
    if [[ "$SHELL" != *zsh* ]]; then
        sudo chsh -s "$(which zsh)" "$USER"
    fi
}

main_menu() {
    while true; do
        CHOICE=$(whiptail --title "Dotfiles Installer v$DOTS_VERSION" --menu "Выбери действие:" 16 60 6 \
            "1" "Проверить зависимости и версию" \
            "2" "Установить yay" \
            "3" "Установить пакеты" \
            "4" "Применить/Обновить dots" \
            "5" "Full Install (Всё и сразу)" \
            "0" "Выход" 3>&1 1>&2 2>&3)
        
        case "$CHOICE" in
            1) check_system ;;
            2) install_yay; whiptail --msgbox "yay готов." 8 40 ;;
            3) install_pkgs; whiptail --msgbox "Пакеты установлены." 8 40 ;;
            4) apply_dots; whiptail --msgbox "Конфиги скопированы. Версия: $DOTS_VERSION." 8 50 ;;
            5) install_pkgs; apply_dots; whiptail --msgbox "Готово. Перезайди в систему." 8 40; exit 0 ;;
            0|*) exit 0 ;;
        esac
    done
}

main_menu
