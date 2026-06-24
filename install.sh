#!/usr/bin/env bash

[[ $EUID -eq 0 ]] && echo "Запускай без sudo." && exit 1

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTS_VERSION="1.6"
DOTS_VER_FILE="$HOME/.config/dots_version"

# Определяем дистрибутив
if grep -qi "arch" /etc/os-release 2>/dev/null; then
    DISTRO="arch"
elif grep -qi "artix" /etc/os-release 2>/dev/null; then
    DISTRO="artix"
else
    DISTRO="arch"
fi

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
    qt5ct qt6ct kvantum pamixer pavucontrol mako nwg-look
    cava zsh zsh-autosuggestions zsh-syntax-highlighting wget curl rsync
    hyprcursor hypridle hyprpaper hyprshot grim slurp
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk polkit
    python python-evdev inotify-tools dunst
    gtk3 gtk4 gnome-themes-extra
)

AUR_PKGS=(
    matugen-bin
    qogir-cursor-theme
    python-pywal16
    quickshell-git
    hyprlauncher-git
    hyprtoolkit-git
)

check_system() {
    clear
    echo "=== Статус системы ($DISTRO) ==="
    [[ -f "$DOTS_VER_FILE" ]] && CURRENT_VER=$(cat "$DOTS_VER_FILE") || CURRENT_VER="Не установлены"
    echo "Dots: установлена [$CURRENT_VER] | скрипт [$DOTS_VERSION]"
    echo "Директория dots: $DOTS_DIR"
    echo "------------------------"
    command -v yay &>/dev/null && echo "[+] yay" || echo "[-] yay"
    for pkg in hyprland waybar alacritty swaybg zsh rofi; do
        pacman -Qs "^$pkg$" &>/dev/null && echo "[+] $pkg" || echo "[-] $pkg"
    done
    echo "------------------------"
    [[ -d "$HOME/.config/hypr" ]] && echo "[+] hypr конфиг есть" || echo "[-] hypr конфиг ОТСУТСТВУЕТ"
    read -n 1 -s -r -p "Нажми любую клавишу..."
}

install_yay() {
    command -v yay &>/dev/null && return
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin && makepkg -si --noconfirm
    cd - && rm -rf /tmp/yay-bin
}

install_pkgs() {
    install_yay
    sudo pacman -S --needed --noconfirm "${PKGS[@]}"
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"

    # GTK тёмная тема
    mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
    cat > ~/.config/gtk-3.0/settings.ini << 'EOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Adwaita
gtk-font-name=Noto Sans 11
gtk-application-prefer-dark-theme=1
EOF
    cp ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini
}

apply_dots() {
    mkdir -p ~/.config ~/Pictures/Wallpapers

    # Копируем все конфиги
    if [[ -d "$DOTS_DIR/config" ]]; then
        cp -af "$DOTS_DIR/config/." ~/.config/
    fi

    [[ -f "$DOTS_DIR/.zshrc" ]]    && cp -f "$DOTS_DIR/.zshrc" ~/
    [[ -f "$DOTS_DIR/.bashrc" ]]   && cp -f "$DOTS_DIR/.bashrc" ~/
    [[ -f "$DOTS_DIR/darkARTIX.png" ]] && cp -f "$DOTS_DIR/darkARTIX.png" ~/Pictures/Wallpapers/

    # Права на скрипты
    find ~/.config/hypr/scripts -type f -name "*.sh" 2>/dev/null -exec chmod +x {} \;
    find ~/.config/hypr/scripts -type f -name "*.py"  2>/dev/null -exec chmod +x {} \;

    # QT тема
    mkdir -p ~/.config/qt5ct ~/.config/qt6ct
    for d in qt5ct qt6ct; do
        cat > ~/.config/$d/$d.conf << 'EOF'
[Appearance]
style=kvantum-dark
icon_theme=Adwaita
EOF
    done

    # Переменные окружения (добавляем если нет)
    grep -q "QT_QPA_PLATFORMTHEME" ~/.bash_profile 2>/dev/null || \
        printf '\nexport QT_QPA_PLATFORMTHEME=qt6ct\nexport QT_STYLE_OVERRIDE=kvantum-dark\n' >> ~/.bash_profile
    grep -q "QT_QPA_PLATFORMTHEME" ~/.zshrc 2>/dev/null || \
        printf '\nexport QT_QPA_PLATFORMTHEME=qt6ct\nexport QT_STYLE_OVERRIDE=kvantum-dark\n' >> ~/.zshrc

    echo "$DOTS_VERSION" > "$DOTS_VER_FILE"

    [[ "$SHELL" != *zsh* ]] && sudo chsh -s "$(which zsh)" "$USER"
}

main_menu() {
    while true; do
        CHOICE=$(whiptail --title "Dotfiles Installer v$DOTS_VERSION ($DISTRO)" \
            --menu "Выбери действие:" 16 60 6 \
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
            4) apply_dots; whiptail --msgbox "Конфиги скопированы. v$DOTS_VERSION" 8 50 ;;
            5) install_pkgs; apply_dots; whiptail --msgbox "Готово. Перезайди в систему." 8 40; exit 0 ;;
            0|*) exit 0 ;;
        esac
    done
}

main_menu
