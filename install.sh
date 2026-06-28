#!/usr/bin/env bash

[[ $EUID -eq 0 ]] && echo "Запускай без sudo." && exit 1

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTS_VERSION="1.8"
DOTS_VER_FILE="$HOME/.config/dots_version"

# Определяем дистрибутив
if grep -qi "artix" /etc/os-release 2>/dev/null; then
    DISTRO="artix"
elif grep -qi "arch" /etc/os-release 2>/dev/null; then
    DISTRO="arch"
else
    DISTRO="arch"
fi

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

# ── Пакеты ──
PKGS=(
    hyprland hyprpaper hypridle hyprlock hyprcursor
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk polkit
    waybar alacritty thunar gvfs rofi-wayland
    swaybg awww mako
    hyprshot cliphist wl-clipboard grim slurp wtype
    pipewire pipewire-pulse pipewire-alsa wireplumber
    pamixer pavucontrol brightnessctl playerctl
    fastfetch btop fzf chafa imagemagick micro rsync
    zsh zsh-autosuggestions zsh-syntax-highlighting ncurses
    ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols noto-fonts noto-fonts-emoji
    qt5ct qt6ct kvantum gnome-themes-extra nwg-look
    gtk3 gtk4
    python python-evdev python-gobject inotify-tools
    network-manager-applet dunst
)

# Базовые сервисы сессии — нужны для звука (PipeWire/XDG_RUNTIME_DIR),
# порталов (dbus → захват экрана в OBS) и сети/блютуза.
PKGS+=(dbus elogind)

# Определяем init system
RUNIT_SVC_PKGS=()
if command -v systemctl &>/dev/null; then
    INIT_SYSTEM="systemd"
    PKGS+=(sddm)
elif command -v runit-init &>/dev/null || [ -d /run/runit ]; then
    INIT_SYSTEM="runit"
    PKGS+=(sddm-runit)
    # runit-обвязки сервисов ставим best-effort (имена могут отличаться)
    RUNIT_SVC_PKGS=(dbus-runit elogind-runit bluez-runit networkmanager-runit)
else
    INIT_SYSTEM="systemd"
    PKGS+=(sddm)
fi

AUR_PKGS=(
    matugen-bin
    awww-git
    qogir-cursor-theme
    python-pywal16
    quickshell-git
    grimblast-git
    hyprpicker
)

# ── Функции ──

install_yay() {
    command -v yay &>/dev/null && return
    echo "Устанавливаю yay..."
    git clone https://aur.archlinux.org/yay-bin.git /tmp/yay-bin
    cd /tmp/yay-bin && makepkg -si --noconfirm
    cd - && rm -rf /tmp/yay-bin
}

install_pkgs() {
    install_yay
    echo "Устанавливаю пакеты..."
    sudo pacman -S --needed --noconfirm "${PKGS[@]}"
    yay -S --needed --noconfirm "${AUR_PKGS[@]}"
    # runit-сервисы — не валим установку, если какого-то пакета нет в репо
    if [[ ${#RUNIT_SVC_PKGS[@]} -gt 0 ]]; then
        sudo pacman -S --needed --noconfirm "${RUNIT_SVC_PKGS[@]}" 2>/dev/null || true
    fi
}

# Включить сервис runit (Artix): /etc/runit/sv/<svc> или /etc/sv/<svc>.
# Гвардим существование — несуществующие сервисы тихо пропускаем.
runit_enable() {
    local svc="$1" src
    for src in "/etc/runit/sv/$svc" "/etc/sv/$svc"; do
        if [[ -d "$src" ]]; then
            sudo ln -sf "$src" /etc/runit/runsvdir/default/ 2>/dev/null
            sudo ln -sf "$src" /run/runit/service/ 2>/dev/null
            return 0
        fi
    done
}

apply_dots() {
    echo "Копирую конфиги..."

    # Создаём директории
    mkdir -p ~/.config ~/Pictures/Wallpapers

    # Копируем содержимое config/ в ~/.config/
    # ВАЖНО: без --delete! Только дополняем/перезаписываем свои файлы,
    # чужие конфиги (браузер, obs, pulse, pipewire и т.д.) НЕ трогаем.
    # Перезаписываемые файлы складываем в датированный бэкап.
    if [[ -d "$DOTS_DIR/config" ]]; then
        local BACKUP="$HOME/.config-backups/$(date +%Y%m%d-%H%M%S)"
        rsync -av --backup --backup-dir="$BACKUP" \
            --exclude='.git' \
            --exclude='*.bak' \
            --exclude='__pycache__' \
            "$DOTS_DIR/config/" ~/.config/
        echo "Бэкап заменённых файлов: $BACKUP"
    fi

    # Копируем dotfiles
    [[ -f "$DOTS_DIR/.zshrc" ]] && cp -f "$DOTS_DIR/.zshrc" ~/
    [[ -f "$DOTS_DIR/.bashrc" ]] && cp -f "$DOTS_DIR/.bashrc" ~/
    [[ -f "$DOTS_DIR/.bash_profile" ]] && cp -f "$DOTS_DIR/.bash_profile" ~/

    # Копируем обои
    [[ -d "$DOTS_DIR/wallpapers" ]] && cp -f "$DOTS_DIR/wallpapers/"* ~/Pictures/Wallpapers/ 2>/dev/null

    # Права на скрипты
    find ~/.config/hypr/scripts -type f -name "*.sh" 2>/dev/null -exec chmod +x {} \;
    find ~/.config/hypr/scripts -type f -name "*.py" 2>/dev/null -exec chmod +x {} \;

    # GTK тёмная тема
    mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
    cat > ~/.config/gtk-3.0/settings.ini << 'GTKEOF'
[Settings]
gtk-theme-name=Adwaita-dark
gtk-icon-theme-name=Adwaita
gtk-font-name=Noto Sans 11
gtk-application-prefer-dark-theme=1
GTKEOF
    cp ~/.config/gtk-3.0/settings.ini ~/.config/gtk-4.0/settings.ini

    # QT тема
    mkdir -p ~/.config/qt5ct ~/.config/qt6ct
    for d in qt5ct qt6ct; do
        cat > ~/.config/$d/$d.conf << 'QTEOF'
[Appearance]
style=kvantum-dark
icon_theme=Adwaita
QTEOF
    done

    # Переменные окружения
    for RC in ~/.bash_profile ~/.zshrc; do
        [[ -f "$RC" ]] || continue
        grep -q "QT_QPA_PLATFORMTHEME" "$RC" 2>/dev/null || \
            printf '\nexport QT_QPA_PLATFORMTHEME=qt6ct\nexport QT_STYLE_OVERRIDE=kvantum-dark\nexport XDG_SESSION_TYPE=wayland\nexport XDG_CURRENT_DESKTOP=Hyprland\n' >> "$RC"
        # XDG_RUNTIME_DIR в шелле = тот же сокет, что у PipeWire → wpctl/звук
        # видят сервер, не "Could not connect to PipeWire".
        grep -q "XDG_RUNTIME_DIR" "$RC" 2>/dev/null || \
            printf 'export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"\n' >> "$RC"
    done

    # Генерируем matugen цвета из текущих обоев
    WALL=$(cat ~/.config/hypr/.wallpaper_path 2>/dev/null || cat ~/.config/hypr/.bg_path 2>/dev/null)
    if [[ -n "$WALL" && -f "$WALL" && -f ~/.config/hypr/scripts/wallpapers/set.sh ]]; then
        bash ~/.config/hypr/scripts/wallpapers/set.sh "$WALL" 2>/dev/null
    fi

    # Включаем сервисы: dbus/elogind (звук+порталы), сеть, блютуз, sddm.
    # dbus и elogind/XDG_RUNTIME_DIR — то, из-за чего на runit «слетал» звук
    # и не работал захват экрана в OBS.
    if [[ "$INIT_SYSTEM" == "systemd" ]]; then
        for s in dbus NetworkManager bluetooth sddm; do
            sudo systemctl enable "$s" 2>/dev/null
        done
    else
        for s in dbus elogind NetworkManager bluetoothd sddm; do
            runit_enable "$s"
        done
    fi

    echo "$DOTS_VERSION" > "$DOTS_VER_FILE"

    # Меняем оболочку на zsh
    [[ "$SHELL" != *zsh* ]] && sudo chsh -s "$(which zsh)" "$USER"
}

# Чистый перенос конфигов — без пакетов, тем, env-переменных, sddm и chsh
copy_configs() {
    echo "Копирую конфиги..."

    mkdir -p ~/.config ~/Pictures/Wallpapers

    # Копируем содержимое config/ в ~/.config/
    # БЕЗ --delete: чужие конфиги не удаляем, перезаписи бэкапим.
    if [[ -d "$DOTS_DIR/config" ]]; then
        local BACKUP="$HOME/.config-backups/$(date +%Y%m%d-%H%M%S)"
        rsync -av --backup --backup-dir="$BACKUP" \
            --exclude='.git' \
            --exclude='*.bak' \
            --exclude='__pycache__' \
            "$DOTS_DIR/config/" ~/.config/
        echo "Бэкап заменённых файлов: $BACKUP"
    fi

    # Копируем dotfiles
    [[ -f "$DOTS_DIR/.zshrc" ]]        && cp -f "$DOTS_DIR/.zshrc" ~/
    [[ -f "$DOTS_DIR/.bashrc" ]]       && cp -f "$DOTS_DIR/.bashrc" ~/
    [[ -f "$DOTS_DIR/.bash_profile" ]] && cp -f "$DOTS_DIR/.bash_profile" ~/

    # Копируем обои
    [[ -d "$DOTS_DIR/wallpapers" ]] && cp -f "$DOTS_DIR/wallpapers/"* ~/Pictures/Wallpapers/ 2>/dev/null

    # Права на скрипты
    find ~/.config/hypr/scripts -type f -name "*.sh" 2>/dev/null -exec chmod +x {} \;
    find ~/.config/hypr/scripts -type f -name "*.py" 2>/dev/null -exec chmod +x {} \;
    chmod +x ~/.config/hypr/start-portals.sh 2>/dev/null

    # Фикс звука/OBS после перезагрузки: гарантируем общий XDG_RUNTIME_DIR в
    # шелле (тот же сокет, что у PipeWire). Сам автозапуск PipeWire+порталов
    # уже в скопированном ~/.config/hypr/start-portals.sh.
    for RC in ~/.bash_profile ~/.zshrc; do
        [[ -f "$RC" ]] || continue
        grep -q "XDG_RUNTIME_DIR" "$RC" 2>/dev/null || \
            printf 'export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"\n' >> "$RC"
    done

    echo "Конфиги перенесены."
}

check_system() {
    clear
    echo "=== Статус системы ($DISTRO, $INIT_SYSTEM) ==="
    [[ -f "$DOTS_VER_FILE" ]] && CURRENT_VER=$(cat "$DOTS_VER_FILE") || CURRENT_VER="Не установлены"
    echo "Dots: установлена [$CURRENT_VER] | скрипт [$DOTS_VERSION]"
    echo "Директория: $DOTS_DIR"
    echo "------------------------"
    command -v yay &>/dev/null && echo "[+] yay" || echo "[-] yay"
    for pkg in hyprland waybar alacritty swaybg zsh rofi fzf chafa mako awww; do
        pacman -Qs "^$pkg$" &>/dev/null && echo "[+] $pkg" || echo "[-] $pkg"
    done
    echo "------------------------"
    [[ -d "$HOME/.config/hypr" ]] && echo "[+] hypr конфиг" || echo "[-] hypr конфиг ОТСУТСТВУЕТ"
    [[ -f "$HOME/.config/waybar/style.css" ]] && echo "[+] waybar style" || echo "[-] waybar style"
    [[ -f "$HOME/.config/hypr/scripts/wallpapers/picker.sh" ]] && echo "[+] picker.sh" || echo "[-] picker.sh"
    read -n 1 -s -r -p "Нажми любую клавишу..."
}

main_menu() {
    while true; do
        CHOICE=$(whiptail --title "Dotfiles Installer v$DOTS_VERSION ($DISTRO)" \
            --menu "Выбери действие:" 18 64 7 \
            "1" "Проверить зависимости и версию" \
            "2" "Установить yay" \
            "3" "Установить пакеты" \
            "4" "Применить/Обновить dots" \
            "5" "Full Install (Всё и сразу)" \
            "6" "Только перенести конфиги (без пакетов/тем)" \
            "0" "Выход" 3>&1 1>&2 2>&3)
        case "$CHOICE" in
            1) check_system ;;
            2) install_yay; whiptail --msgbox "yay готов." 8 40 ;;
            3) install_pkgs; whiptail --msgbox "Пакеты установлены." 8 40 ;;
            4) apply_dots; whiptail --msgbox "Конфиги скопированы. v$DOTS_VERSION" 8 50 ;;
            5) install_pkgs; apply_dots; whiptail --msgbox "Готово. Перезайди в систему." 8 40; exit 0 ;;
            6) copy_configs; whiptail --msgbox "Конфиги перенесены в ~/.config" 8 50 ;;
            0|*) exit 0 ;;
        esac
    done
}

main_menu
