#!/usr/bin/env bash
# Кэширует раскладку — не мерцает при wtype
CACHE="/tmp/waybar_lang"
cur=$(hyprctl devices -j 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
for k in d.get('keyboards',[]):
    n=k['name']
    if 'key' in n.lower() or n=='cx-2.4g-wireless-receiver':
        a=k.get('active_keymap','')
        if a: print(a[:2].lower()); break
" 2>/dev/null)
[ -n "$cur" ] && echo "$cur" > "$CACHE"
cat "$CACHE" 2>/dev/null || echo "en"
