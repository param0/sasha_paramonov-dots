#!/usr/bin/env bash
# -----------------------------------------------------------------------------
#  Monitor control center for Hyprland  (Super+P)
#  - Win+P-style projection (internal / external / duplicate / extend)
#  - Monitor overclock (auto-tuner + manual + custom CVT modeline)
#  - 15-second "keep these settings?" confirm, auto-revert on timeout/reject
#  - Presets: create / apply / edit / delete (auto-delete on hard failure)
#  - CS2 stretched / 4:3 custom resolutions
#  Kept settings are written to monitors.conf, so they survive reboot AND a
#  hyprctl reload (e.g. from the wallpaper scripts) -> overclock is not lost.
#  UI colours come from matugen; style follows the wallpaper picker.
# -----------------------------------------------------------------------------
set -uo pipefail

CACHE_DIR="$HOME/.cache/monitor-settings"
THUMB_FILE="$CACHE_DIR/wall.txt"
PREVIEW_FILE="$CACHE_DIR/preview.txt"
PRESET_FILE="$HOME/.config/hypr/monitor-presets.conf"
MONITORS_CONF="$HOME/.config/hypr/configs/monitors.conf"
COLORS_JSON="$HOME/.cache/quickshell-colors.json"
WALL_PATH="$HOME/.config/hypr/.wallpaper_path"
mkdir -p "$CACHE_DIR"

MON_JSON=""                 # cached `hyprctl monitors all -j`
refresh_json() { MON_JSON="$(hyprctl monitors all -j 2>/dev/null)"; }

apply()  { hyprctl keyword monitor "$1" >/dev/null 2>&1; }
notify() { command -v notify-send >/dev/null 2>&1 && notify-send -a Monitor "Monitor" "$1"; }

# -- matugen colours -> fzf theme ---------------------------------------------
load_colors() {
    FZF_COLORS=$(C="$COLORS_JSON" python3 -c '
import json,os
d={}
try: d=json.load(open(os.environ["C"]))
except Exception: pass
g=lambda k,f: d.get(k,f)
bg=g("background","#0a0a0f"); bg2=g("surfaceContainer","#15151f")
fg=g("text","#c0caf5"); pri=g("primary","#7aa2f7"); sec=g("secondary","#bb9af7")
err=g("error","#f7768e"); sub=g("subtext","#9aa5ce")
print(f"bg:{bg},bg+:{bg2},fg:{fg},fg+:#ffffff,info:{pri},prompt:{pri},"
      f"pointer:{sec},marker:{sec},hl:{err},hl+:{err},header:{sub},"
      f"border:{pri},spinner:{sec},gutter:{bg}")' 2>/dev/null)
    [ -n "$FZF_COLORS" ] || FZF_COLORS="bg:#0a0a0f,bg+:#15151f,fg:#c0caf5,fg+:#ffffff,info:#7aa2f7,prompt:#ffffff,pointer:#bb9af7,hl:#f7768e,hl+:#f7768e"
}

# -- wallpaper thumbnail (cached, regenerated only when wallpaper changes) -----
gen_thumb() {
    local wall
    wall=$(cat "$WALL_PATH" 2>/dev/null)
    if [ -f "$wall" ] && command -v chafa >/dev/null 2>&1; then
        if [ ! -s "$THUMB_FILE" ] || [ "$wall" -nt "$THUMB_FILE" ]; then
            chafa --size=42x16 --symbols braille --scale max "$wall" >"$THUMB_FILE" 2>/dev/null
        fi
    else
        : >"$THUMB_FILE"
    fi
}

build_preview() {
    gen_thumb
    {
        [ -s "$THUMB_FILE" ] && cat "$THUMB_FILE"
        printf '\n  \033[1mМониторы\033[0m\n'
        mlist | sed 's/\t/   /; s/^/   /'
        printf '\n  \033[1mПресеты\033[0m\n'
        if preset_lines | grep -q .; then
            preset_lines | cut -f1 | sed 's/^/   - /'
        else
            printf '   нет\n'
        fi
    } >"$PREVIEW_FILE"
}

# -- fzf wrappers (style mirrors the wallpaper picker) -------------------------
HDR="  ↑↓ выбор | Enter выбрать | Esc назад"
menu() { # $1 prompt  $2 header   (options on stdin)
    fzf --prompt="$1" --header="$2" --height=100% --layout=reverse \
        --info=inline --border=rounded --color="$FZF_COLORS" --no-multi --no-sort
}
menu_preview() { # like menu(), with wallpaper/status preview pane
    fzf --prompt="$1" --header="$2" --height=100% --layout=reverse \
        --info=inline --border=rounded --color="$FZF_COLORS" --no-multi --no-sort \
        --preview "cat '$PREVIEW_FILE' 2>/dev/null" \
        --preview-window=right:46%:wrap:noborder
}
ask() { local r; printf '\033[2J\033[H\n  %s' "$1" >/dev/tty; read -e -r r </dev/tty; printf '%s' "$r"; }

# -- JSON readers (operate on cached MON_JSON, no extra hyprctl spawn) ---------
mlist() { printf '%s' "$MON_JSON" | python3 -c '
import json,sys
try: m=json.load(sys.stdin)
except Exception: m=[]
for d in m:
    st="ВЫКЛ" if d.get("disabled") else "%dx%d@%dHz x%s"%(d["width"],d["height"],round(d.get("refreshRate",0)),d.get("scale",1))
    print("%s\t%s"%(d["name"],st))'; }

mnames() { mlist | cut -f1; }

minfo() { printf '%s' "$MON_JSON" | M="$1" python3 -c '
import json,os,sys
try: m=json.load(sys.stdin)
except Exception: m=[]
d=next((x for x in m if x["name"]==os.environ["M"]),{})
print(d.get("width",0),d.get("height",0),round(d.get("refreshRate",0)),
      d.get("x",0),d.get("y",0),d.get("scale",1),d.get("transform",0),
      int(bool(d.get("disabled"))))'; }

mmodes() { printf '%s' "$MON_JSON" | M="$1" python3 -c '
import json,os,sys
try: m=json.load(sys.stdin)
except Exception: m=[]
d=next((x for x in m if x["name"]==os.environ["M"]),{})
for s in d.get("availableModes",[]): print(s.replace("Hz",""))'; }

internal_mon() { printf '%s' "$MON_JSON" | python3 -c '
import json,sys
try: m=json.load(sys.stdin)
except Exception: m=[]
for d in m:
    if d["name"].startswith(("eDP","LVDS","DSI")): print(d["name"]); break
else: print(m[0]["name"] if m else "")'; }

current_args() { # reconstruct full monitor arg string for revert/save
    local mon="$1" w h hz x y scale tr dis
    read -r w h hz x y scale tr dis < <(minfo "$mon")
    [ "$dis" = "1" ] && { printf '%s,disable' "$mon"; return; }
    printf '%s,%sx%s@%s,%sx%s,%s,transform,%s' "$mon" "$w" "$h" "$hz" "$x" "$y" "$scale" "$tr"
}

pick_monitor() { # echoes a monitor name (auto-selects when only one)
    local -a names; mapfile -t names < <(mnames)
    [ "${#names[@]}" -eq 0 ] && return 1
    if [ "${#names[@]}" -eq 1 ]; then printf '%s' "${names[0]}"; return 0; fi
    local s; s=$(mlist | menu "  Монитор > " "$HDR") || return 1
    [ -n "$s" ] && printf '%s' "$s" | cut -f1
}

# -- 15-second confirmation with auto-revert ----------------------------------
confirm_keep() {
    local s=15 k
    # Read keys from the controlling terminal directly: when the script is
    # launched via `alacritty -e`, stdin may be at EOF, which makes `read -t`
    # return instantly and burn the whole countdown in milliseconds.
    exec 3</dev/tty 2>/dev/null || { command -v tput >/dev/null 2>&1 && tput cnorm 2>/dev/null; return 1; }
    # Drain buffered input first — the Enter used to pick the fzf item is still
    # in the terminal buffer and would otherwise be eaten by the first read,
    # instantly "keeping" with no visible countdown.
    while read -rsn1 -t 0.05 -u 3 _; do :; done
    command -v tput >/dev/null 2>&1 && tput civis >/dev/tty 2>/dev/null
    while [ "$s" -gt 0 ]; do
        printf '\r\033[K  \033[1mОставить настройки?\033[0m  [Enter] оставить · [любая клавиша] откат   откат через %2d с ' "$s" >/dev/tty
        if read -rsn1 -t 1 -u 3 k; then
            printf '\n' >/dev/tty; command -v tput >/dev/null 2>&1 && tput cnorm >/dev/tty 2>/dev/null
            exec 3<&-
            case "$k" in ''|y|Y|д|Д) return 0 ;; *) return 1 ;; esac
        fi
        s=$((s-1))
    done
    printf '\n' >/dev/tty; command -v tput >/dev/null 2>&1 && tput cnorm >/dev/tty 2>/dev/null
    exec 3<&-
    return 1
}

# $1 new monitor args   $2 expected "WxH" hard-check (optional)   $3 preset to delete if it HARD-fails (optional)
apply_with_confirm() {
    local newargs="$1" expect="${2:-}" delp="${3:-}" mon prev cw ch ew eh
    mon="${newargs%%,*}"
    prev="$(current_args "$mon")"
    apply "$newargs"; refresh_json

    if [ -n "$expect" ]; then          # did the mode physically take?
        ew="${expect%x*}"; eh="${expect#*x}"; eh="${eh%@*}"
        read -r cw ch _ < <(minfo "$mon")
        if [ "$cw" != "$ew" ] || [ "$ch" != "$eh" ]; then
            apply "$prev"; refresh_json
            notify "Режим не применился — откат${delp:+; пресет «$delp» удалён}"
            [ -n "$delp" ] && preset_del "$delp"
            return 1
        fi
    fi

    printf '\033[2J\033[H\n' >/dev/tty
    [ -s "$THUMB_FILE" ] && cat "$THUMB_FILE" >/dev/tty
    printf '\n  \033[1mПрименено:\033[0m %s\n\n' "$newargs" >/dev/tty
    if confirm_keep; then
        make_permanent "$newargs"          # persist -> survives reboot + reload
        notify "Применено и сохранено: $newargs"; return 0
    fi
    apply "$prev"; refresh_json
    notify "Откат — настройки не подтверждены"   # user declined -> preset kept
    return 1
}

# -- overclock ----------------------------------------------------------------
# Self-contained CVT reduced-blanking (v1) modeline generator — no external deps.
# Echoes "pixelclock hdisp hss hse htot vdisp vss vse vtot +hsync -vsync".
gen_modeline() { # w h hz
    W="$1" H="$2" R="$3" python3 -c '
import os,math
hd=int(os.environ["W"]); vd=int(os.environ["H"]); vr=float(os.environ["R"])
CELL=8; MIN_VP=3; RB_VBLANK=460.0; RB_HSYNC=32; RB_HBLANK=160; RB_VFP=3; STEP=0.25
hd=(hd//CELL)*CELL
ar=hd/vd if vd else 0
def near(a,b): return abs(ar-b)<0.05
vsync = 4 if near(ar,4/3) else 5 if near(ar,16/9) else 6 if near(ar,16/10) \
        else 7 if (near(ar,5/4) or near(ar,15/9)) else 10
hper=((1e6/vr)-RB_VBLANK)/(vd+MIN_VP)
vbi=math.ceil(RB_VBLANK/hper)
act_vbi=max(vbi, RB_VFP+vsync+MIN_VP)
tvl=act_vbi+vd; tpx=RB_HBLANK+hd
clk=round((vr*tvl*tpx/1e6)/STEP)*STEP
hss=hd+48; hse=hss+RB_HSYNC
vss=vd+RB_VFP; vse=vss+vsync
print("%.2f %d %d %d %d %d %d %d %d +hsync -vsync"%(clk,hd,hss,hse,tpx,vd,vss,vse,tvl))' 2>/dev/null
}

# build hyprctl args for a target refresh via a real CVT-R modeline (true OC)
oc_args() { # mon w h hz x y scale  -> echoes monitor args
    local mon="$1" w="$2" h="$3" hz="$4" x="$5" y="$6" scale="$7" ml=""
    if command -v cvt >/dev/null 2>&1; then
        ml=$(cvt -r "$w" "$h" "$hz" 2>/dev/null | awk -F'"' '/Modeline/{print $3}' | sed 's/^ *//')
    fi
    [ -n "$ml" ] || ml=$(gen_modeline "$w" "$h" "$hz")
    if [ -n "$ml" ]; then printf '%s,modeline %s,%sx%s,%s' "$mon" "$ml" "$x" "$y" "$scale"
    else                  printf '%s,%sx%s@%s,%sx%s,%s' "$mon" "$w" "$h" "$hz" "$x" "$y" "$scale"; fi
}

oc_apply() { # mon w h hz x y scale  [preset-to-delete-on-fail]
    local mon="$1" w="$2" h="$3" hz="$4" x="$5" y="$6" scale="$7" delp="${8:-}"
    apply_with_confirm "$(oc_args "$mon" "$w" "$h" "$hz" "$x" "$y" "$scale")" "${w}x${h}" "$delp"
}

# auto-tuner: try highest->lowest, first that physically applies AND is confirmed wins
gen_overclock() {
    local mon="$1" w h hz x y scale tr dis t
    read -r w h hz x y scale tr dis < <(minfo "$mon")
    notify "Авто-разгон $mon: пробую от $((hz+30)) Hz вниз"
    for t in $((hz+30)) $((hz+20)) $((hz+15)) $((hz+10)) $((hz+5)); do
        printf '\033[2J\033[H\n  Пробую %s @ %s Hz ...\n' "${w}x${h}" "$t" >/dev/tty
        if oc_apply "$mon" "$w" "$h" "$t" "$x" "$y" "$scale"; then
            preset_save "OC ${w}x${h}@${t}" "$(oc_args "$mon" "$w" "$h" "$t" "$x" "$y" "$scale")"
            notify "Оптимум: $t Hz; пресет «OC ${w}x${h}@${t}» сохранён"
            return 0
        fi
    done
    notify "Стабильный разгон не найден — оставлено $hz Hz"
}

overclock_menu() {
    local mon="$1" w h hz x y scale tr dis sel target ml nm
    while :; do
        refresh_json
        read -r w h hz x y scale tr dis < <(minfo "$mon")
        sel=$(printf '%s\n' \
            "Назад" \
            "Авто-разгон (подобрать оптимум)" \
            "Выбрать частоту вручную" \
            "Своя modeline" \
            "Сохранить текущий режим в пресет" \
            | menu "  Разгон $mon · ${w}x${h}@${hz}Hz > " "$HDR")
        case "$sel" in
            Назад|"") return ;;
            Авто*)   gen_overclock "$mon" ;;
            *вручную*)
                target=$(for t in $((hz+5)) $((hz+10)) $((hz+15)) $((hz+20)) $((hz+30)) $((hz+45)); do
                            echo "$t Hz"; done | menu "  Частота > " "  Цель (текущая ${hz} Hz)")
                [ -z "$target" ] && continue
                oc_apply "$mon" "$w" "$h" "${target%% *}" "$x" "$y" "$scale" ;;
            *modeline*)
                ml=$(ask "modeline (pixelclock hdisp hss hse htot vdisp vss vse vtot +hsync -vsync): ")
                [ -z "$ml" ] && continue
                apply_with_confirm "$mon,modeline $ml,${x}x${y},$scale" ;;
            *Сохранить*)
                nm=$(ask "Имя пресета: "); [ -z "$nm" ] && continue
                preset_save "$nm" "$(current_args "$mon")"; notify "Пресет «$nm» сохранён" ;;
        esac
    done
}

# -- presets (CRUD) -----------------------------------------------------------
ensure_presets() {
    [ -f "$PRESET_FILE" ] && return
    mkdir -p "${PRESET_FILE%/*}"
    cat >"$PRESET_FILE" <<'EOF'
# Пресеты монитора — формат:  имя<TAB>аргументы hyprctl monitor
# пример:  144 OC	eDP-1,1920x1080@165,0x0,1
EOF
}
preset_lines() { ensure_presets; grep -vE '^\s*(#|$)' "$PRESET_FILE" 2>/dev/null; }
preset_get()   { preset_lines | awk -F'\t' -v n="$1" '$1==n{print $2; exit}'; }
preset_del()   {
    ensure_presets
    local tmp; tmp="$(mktemp)"
    awk -F'\t' -v n="$1" 'NF==0 || $0 ~ /^[[:space:]]*#/ || $1!=n' "$PRESET_FILE" >"$tmp" && mv "$tmp" "$PRESET_FILE"
}
preset_save()  { ensure_presets; preset_del "$1"; printf '%s\t%s\n' "$1" "$2" >>"$PRESET_FILE"; }

reset_monitors() { # re-apply ONLY the monitor= lines from monitors.conf (no global reload)
    if [ ! -f "$MONITORS_CONF" ]; then notify "monitors.conf не найден"; return 1; fi
    local line
    while IFS= read -r line; do
        line="${line#*=}"          # strip leading 'monitor='
        apply "$line"
    done < <(grep -E '^[[:space:]]*monitor[[:space:]]*=' "$MONITORS_CONF")
    refresh_json
    notify "Мониторы сброшены к monitors.conf"
}

make_permanent() { # write the chosen monitor line into monitors.conf
    local args="$1" mon tmp
    mon="${args%%,*}"
    [ -f "$MONITORS_CONF" ] || return 1
    tmp="$(mktemp)"
    grep -vE "^[[:space:]]*monitor[[:space:]]*=[[:space:]]*${mon}," "$MONITORS_CONF" >"$tmp"
    printf 'monitor=%s\n' "$args" >>"$tmp"
    mv "$tmp" "$MONITORS_CONF"
}

edit_preset() {
    local name="$1" args mon w h hz x y scale tr dis newhz
    args=$(preset_get "$name"); mon="${args%%,*}"
    read -r w h hz x y scale tr dis < <(minfo "$mon")
    newhz=$(ask "Новая частота для «$name» (Гц), сейчас на $mon ${hz}: ")
    [ -z "$newhz" ] && return
    preset_save "$name" "$(oc_args "$mon" "$w" "$h" "$newhz" "$x" "$y" "$scale")"
    notify "Пресет «$name» обновлён -> ${newhz}Hz"
}

presets_menu() {
    local sel name args act nm mon
    while :; do
        refresh_json
        sel=$( { printf '%s\n' "Назад" "Создать из текущего режима" "----------"; \
                 preset_lines | sed 's/\t/   ->   /'; } \
               | menu "  Пресеты > " "$HDR")
        case "$sel" in
            Назад|""|*"----"*) return ;;
            *Создать*)
                nm=$(ask "Имя пресета: "); [ -z "$nm" ] && continue
                mon=$(pick_monitor) || continue
                preset_save "$nm" "$(current_args "$mon")"; notify "Пресет «$nm» создан" ;;
            *)
                name="${sel%%   ->   *}"
                args=$(preset_get "$name")
                [ -z "$args" ] && continue
                act=$(printf '%s\n' "Применить" "Изменить частоту" "Сделать постоянным" "Удалить" "Назад" \
                      | menu "  $name > " "  $args")
                case "$act" in
                    Применить) apply_with_confirm "$args" "" "$name" ;;
                    *Изменить*)  edit_preset "$name" ;;
                    *постоянным*) make_permanent "$args" && notify "«$name» записан в monitors.conf" ;;
                    Удалить)   preset_del "$name"; notify "Пресет «$name» удалён" ;;
                esac ;;
        esac
    done
}

# -- CS2 / custom resolutions -------------------------------------------------
cs2_menu() {
    local mon w h hz x y scale tr dis sel r cw ch s nm
    mon=$(pick_monitor) || return
    while :; do
        refresh_json
        read -r w h hz x y scale tr dis < <(minfo "$mon")
        sel=$(printf '%s\n' \
            "Назад" \
            "1280x960    4:3  классика CS2" \
            "1440x1080   4:3  чёткий стретч" \
            "1024x768    4:3  лёгкий" \
            "1280x1024   5:4" \
            "1176x664    16:9 low" \
            "1280x720    16:9 720p" \
            "1080x1080   1:1  square" \
            "Вернуть родное ${w}x${h}" \
            | menu "  CS2 разрешения · $mon > " "$HDR")
        case "$sel" in
            Назад|"") return ;;
            Вернуть*) apply_with_confirm "$mon,${w}x${h}@${hz},${x}x${y},$scale" ;;
            [0-9]*)
                r="${sel%% *}"; cw="${r%x*}"; ch="${r#*x}"
                if apply_with_confirm "$mon,${r}@${hz},${x}x${y},$scale" "${cw}x${ch}"; then
                    s=$(printf '%s\n' "Нет" "Да — сохранить пресет" | menu "  Сохранить как пресет? > " "")
                    if [ "$s" = "Да — сохранить пресет" ]; then
                        nm=$(ask "Имя: "); [ -n "$nm" ] && preset_save "$nm" "$mon,${r}@${hz},${x}x${y},$scale"
                    fi
                fi ;;
        esac
    done
}

# -- per-monitor fine settings ------------------------------------------------
configure_monitor() {
    local mon="$1" sel pos scale mode s r t target x y
    while :; do
        refresh_json
        read -r _ _ _ x y scale _ _ < <(minfo "$mon")
        pos="${x}x${y}"
        sel=$(printf '%s\n' \
            "Назад" \
            "Разгон" \
            "Разрешение и частота" \
            "Масштаб (x$scale)" \
            "Поворот" \
            "Зеркалить с другого монитора" \
            "Выключить монитор" \
            | menu "  $mon > " "$HDR")
        case "$sel" in
            Назад|"") return ;;
            Разгон) overclock_menu "$mon" ;;
            *Разрешение*)
                mode=$(mmodes "$mon" | menu "  Режим > " "  Разрешение@частота")
                [ -n "$mode" ] && apply_with_confirm "$mon,$mode,$pos,$scale" "${mode%@*}" ;;
            *Масштаб*)
                s=$(printf '%s\n' 1 1.25 1.5 1.75 2 2.5 | menu "  Scale > " "  Множитель")
                [ -n "$s" ] && apply_with_confirm "$mon,preferred,$pos,$s" ;;
            Поворот)
                r=$(printf '%s\n' "0 норма" "90" "180" "270" | menu "  Поворот > " "  Ориентация (градусы)")
                case "$r" in 0*) t=0;; 90*) t=1;; 180*) t=2;; 270*) t=3;; *) t="";; esac
                [ -n "$t" ] && apply_with_confirm "$mon,preferred,$pos,$scale,transform,$t" ;;
            *Зеркалить*)
                target=$(mnames | grep -vx "$mon" | menu "  Источник > " "  Зеркалить ИЗ монитора")
                [ -n "$target" ] && apply_with_confirm "$mon,preferred,auto,$scale,mirror,$target" ;;
            *Выключить*) apply "$mon,disable"; notify "$mon выключен"; return ;;
        esac
    done
}

# -- projection presets (Win+P) -----------------------------------------------
projection() {
    local internal n; internal="$(internal_mon)"
    local -a ext; mapfile -t ext < <(mnames | grep -vx "$internal")
    case "$1" in
        internal) apply "$internal,preferred,auto,1"; for n in "${ext[@]}"; do apply "$n,disable"; done
                  notify "Только встроенный: $internal" ;;
        external) [ "${#ext[@]}" -eq 0 ] && { notify "Внешних мониторов нет"; return; }
                  apply "$internal,disable"; for n in "${ext[@]}"; do apply "$n,preferred,auto,1"; done
                  notify "Только внешний" ;;
        duplicate) [ "${#ext[@]}" -eq 0 ] && { notify "Внешних мониторов нет"; return; }
                   apply "$internal,preferred,auto,1"; for n in "${ext[@]}"; do apply "$n,preferred,auto,1,mirror,$internal"; done
                   notify "Дублирование экрана" ;;
        extend)   apply "$internal,preferred,auto,1"; for n in "${ext[@]}"; do apply "$n,preferred,auto-right,1"; done
                  notify "Расширение рабочего стола" ;;
    esac
    refresh_json
}

# -- main menu ----------------------------------------------------------------
main() {
    local sel mon
    while :; do
        refresh_json
        build_preview
        sel=$( { printf '%s\n' \
            "Разгон монитора" \
            "Пресеты" \
            "CS2 / кастомные разрешения" \
            "Проекция: только встроенный" \
            "Проекция: только внешний" \
            "Проекция: дублировать" \
            "Проекция: расширить" \
            "Откатить мониторы к monitors.conf" \
            "----------------------------------" ; \
            mlist | sed 's/^/Настроить: /' ; } \
            | menu_preview "  Монитор > " "  ↑↓ выбор | Enter выбрать | Esc выход")
        case "$sel" in
            ""|*"----"*) exit 0 ;;
            "Разгон монитора") mon=$(pick_monitor) && [ -n "$mon" ] && overclock_menu "$mon" ;;
            "Пресеты") presets_menu ;;
            CS2*) cs2_menu ;;
            *"только встроенный"*) projection internal ;;
            *"только внешний"*)    projection external ;;
            *дублировать*)         projection duplicate ;;
            *расширить*)           projection extend ;;
            *Откатить*)            reset_monitors ;;
            "Настроить: "*) mon=$(printf '%s' "${sel#Настроить: }" | cut -f1); configure_monitor "$mon" ;;
        esac
    done
}

command -v hyprctl >/dev/null 2>&1 || { notify "hyprctl не найден"; exit 1; }
load_colors
main
