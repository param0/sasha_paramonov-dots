#!/usr/bin/env bash
# Monitor settings / projection menu (Win+P style) for Hyprland.
# Launched floating via Super+P. Changes are applied live with `hyprctl`
# (runtime only — a `hyprctl reload` / relogin reverts to monitors.conf).
set -uo pipefail

FZF_COLORS="bg:#0a0a0f,bg+:#15151f,fg:#c0caf5,fg+:#ffffff,info:#7aa2f7,prompt:#ffffff,pointer:#bb9af7,hl:#f7768e,hl+:#f7768e"

menu() { # $1 prompt, $2 header  (options on stdin)
    fzf --prompt="$1" --header="$2" \
        --height=100% --layout=reverse --info=inline --border=rounded \
        --color="$FZF_COLORS" --no-multi --no-sort
}

notify() { command -v notify-send >/dev/null 2>&1 && notify-send -a "Monitor" "Monitor" "$1"; }
apply()  { hyprctl keyword monitor "$1" >/dev/null 2>&1; }

# --- helpers reading hyprctl JSON (monitor name passed via env to avoid quoting) ---
mon_field() { M="$1" F="$2" python3 -c '
import json,os,subprocess
m=json.loads(subprocess.check_output(["hyprctl","monitors","all","-j"]))
d=next((x for x in m if x["name"]==os.environ["M"]),{})
print(d.get(os.environ["F"],""))'; }

mon_modes() { M="$1" python3 -c '
import json,os,subprocess
m=json.loads(subprocess.check_output(["hyprctl","monitors","all","-j"]))
d=next((x for x in m if x["name"]==os.environ["M"]),{})
for s in d.get("availableModes",[]): print(s.replace("Hz",""))'; }

mon_list() { python3 -c '
import json,subprocess
m=json.loads(subprocess.check_output(["hyprctl","monitors","all","-j"]))
for d in m:
    if d.get("disabled"):
        st="OFF"
    else:
        st="%dx%d@%dHz  x%s" % (d["width"],d["height"],round(d.get("refreshRate",0)),d.get("scale",1))
    print("%s\t%s" % (d["name"], st))'; }

mon_names() { mon_list | cut -f1; }

internal_mon() { python3 -c '
import json,subprocess
m=json.loads(subprocess.check_output(["hyprctl","monitors","all","-j"]))
for d in m:
    if d["name"].startswith(("eDP","LVDS","DSI")):
        print(d["name"]); break
else:
    print(m[0]["name"] if m else "")'; }

# ---------------------------------------------------------------- projection presets
projection() {
    local internal externals n
    internal=$(internal_mon)
    mapfile -t externals < <(mon_names | grep -vx "$internal")

    case "$1" in
        internal)
            apply "$internal,preferred,auto,1"
            for n in "${externals[@]}"; do apply "$n,disable"; done
            notify "Только встроенный: $internal" ;;
        external)
            if [ ${#externals[@]} -eq 0 ]; then notify "Внешних мониторов нет"; return; fi
            apply "$internal,disable"
            for n in "${externals[@]}"; do apply "$n,preferred,auto,1"; done
            notify "Только внешний" ;;
        duplicate)
            if [ ${#externals[@]} -eq 0 ]; then notify "Внешних мониторов нет"; return; fi
            apply "$internal,preferred,auto,1"
            for n in "${externals[@]}"; do apply "$n,preferred,auto,1,mirror,$internal"; done
            notify "Дублирование экрана" ;;
        extend)
            apply "$internal,preferred,auto,1"
            for n in "${externals[@]}"; do apply "$n,preferred,auto-right,1"; done
            notify "Расширение рабочего стола" ;;
    esac
}

# ---------------------------------------------------------------- per-monitor submenu
configure_monitor() {
    local mon="$1" sel pos scale mode
    while :; do
        pos="$(mon_field "$mon" x)x$(mon_field "$mon" y)"
        scale="$(mon_field "$mon" scale)"
        sel=$(printf '%s\n' \
            "↩  Назад" \
            "🖥  Разрешение и частота" \
            "🔍  Масштаб (сейчас x$scale)" \
            "🔄  Поворот" \
            "🪞  Зеркалить на другой монитор" \
            "⏻  Выключить монитор" \
            | menu "  $mon > " "  Enter — выбрать | Esc — назад")
        case "$sel" in
            *Назад|"") return ;;
            *Разрешение*)
                mode=$(mon_modes "$mon" | menu "  Режим > " "  Разрешение@частота")
                [ -n "$mode" ] && apply "$mon,$mode,$pos,$scale" && notify "$mon → $mode" ;;
            *Масштаб*)
                local s
                s=$(printf '%s\n' 1 1.25 1.5 1.75 2 2.5 | menu "  Scale > " "  Множитель масштаба")
                [ -n "$s" ] && apply "$mon,preferred,$pos,$s" && notify "$mon → масштаб x$s" ;;
            *Поворот*)
                local r t
                r=$(printf '%s\n' "0°  (норма)" "90°" "180°" "270°" | menu "  Поворот > " "  Ориентация")
                case "$r" in 0*) t=0;; 90*) t=1;; 180*) t=2;; 270*) t=3;; *) t="";; esac
                [ -n "$t" ] && apply "$mon,preferred,$pos,$scale,transform,$t" && notify "$mon → поворот ${r%% *}" ;;
            *Зеркалить*)
                local target
                target=$(mon_names | grep -vx "$mon" | menu "  Источник > " "  Зеркалить ИЗ монитора")
                [ -n "$target" ] && apply "$mon,preferred,auto,$scale,mirror,$target" && notify "$mon зеркалит $target" ;;
            *Выключить*)
                apply "$mon,disable" && notify "$mon выключен"; return ;;
        esac
    done
}

# ---------------------------------------------------------------- main menu
main() {
    local sel mon
    while :; do
        sel=$( { printf '%s\n' \
            "🖥  Только встроенный экран" \
            "🖵  Только внешний экран" \
            "🔁  Дублировать" \
            "↔  Расширить" \
            "──────────────────────────" ; \
            mon_list | sed 's/^/⚙  /' ; } \
            | menu "  Монитор > " "  Win+P: проекция | ⚙ строки — тонкая настройка | Esc — выход")
        case "$sel" in
            ""|*"──────"*) exit 0 ;;
            *"Только встроенный"*) projection internal ;;
            *"Только внешний"*)    projection external ;;
            *Дублировать*)         projection duplicate ;;
            *Расширить*)           projection extend ;;
            "⚙  "*)
                mon=$(printf '%s' "${sel#⚙  }" | cut -f1)
                configure_monitor "$mon" ;;
        esac
    done
}

command -v hyprctl >/dev/null 2>&1 || { notify "hyprctl не найден"; exit 1; }
main
