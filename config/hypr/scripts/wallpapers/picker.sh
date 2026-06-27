#!/usr/bin/env bash
DIR="$HOME/Pictures/Wallpapers"
CACHE="$HOME/.cache/wallpaper-picker"
mkdir -p "$CACHE"

FILES=()
shopt -s nullglob
for ext in jpg jpeg png gif webp bmp; do
    for f in "$DIR"/*."$ext"; do
        FILES+=("$f")
    done
done
shopt -u nullglob
[ ${#FILES[@]} -eq 0 ] && notify-send "Wallpapers" "None found" && exit 1

TMP="$CACHE/list.txt"
printf '%s\n' "${FILES[@]##*/}" | sort > "$TMP"

PREVIEW_CACHE="$CACHE/previews"
mkdir -p "$PREVIEW_CACHE"

cat > "$CACHE/preview.sh" << PVSCRIPT
#!/bin/bash
F="$HOME/Pictures/Wallpapers/\$1"
[ -f "\$F" ] || exit 0
PC="$PREVIEW_CACHE/\$1"
if [ ! -f "\$PC" ]; then
    convert "\$F" -resize 640x360^ -gravity center -extent 640x360 "\$PC" 2>/dev/null
fi
TERM=xterm-256color chafa --size=90x32 --symbols braille --scale max "\$PC" 2>/dev/null
PVSCRIPT
chmod +x "$CACHE/preview.sh"

# Always dark picker
FZF_COLORS="bg:#0a0a0f,bg+:#15151f,fg:#c0caf5,fg+:#ffffff,info:#7aa2f7,prompt:#ffffff,pointer:#bb9af7,hl:#f7768e,hl+:#f7768e"

SEL=$(cat "$TMP" | fzf \
    --prompt="  Wallpaper > " \
    --preview "bash $CACHE/preview.sh {1}" \
    --preview-window=right:70%:noborder \
    --height=100% \
    --layout=reverse \
    --info=inline \
    --border=rounded \
    --color="$FZF_COLORS" \
    --header="  ↑↓ Move | Enter Apply | Esc Cancel")

[ -z "$SEL" ] && exit 0

bash "$HOME/.config/hypr/scripts/wallpapers/set.sh" "$DIR/$SEL"
notify-send "Wallpaper" "Set: $SEL"
