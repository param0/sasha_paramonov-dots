#!/usr/bin/env bash
DIR=${1:-next}
MODE=$(cat /tmp/hypr-desktop-mode 2>/dev/null || echo "tiling")

if [ "$DIR" = "prev" ]; then
    hyprctl dispatch cyclenext prev
else
    hyprctl dispatch cyclenext
fi

[ "$MODE" != "infinite" ] && exit 0

python3 << 'PYEOF'
import json, os, socket, subprocess

sig = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', '')
rt = os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')
CMD_SOCK = f"{rt}/hypr/{sig}/.socket.sock"

def get_json(cmd):
    try: return json.loads(subprocess.check_output(['hyprctl', cmd, '-j'], timeout=0.5))
    except: return []

fw = get_json("activewindow")
if not fw: exit()
m = next((x for x in get_json("monitors") if x.get('focused')), None)
if not m: exit()

cx, cy = m['x'] + m['width']//2, m['y'] + m['height']//2
dx = cx - (fw['at'][0] + fw['size'][0]//2)
dy = cy - (fw['at'][1] + fw['size'][1]//2)

if dx == 0 and dy == 0: exit()
ws_id = fw.get('workspace',{}).get('id')

moves = [f"dispatch movewindowpixel exact {w['at'][0]+dx} {w['at'][1]+dy},address:{w['address']}"
         for w in get_json("clients")
         if w.get('floating') and w.get('workspace',{}).get('id') == ws_id]

if moves:
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(CMD_SOCK)
            s.sendall(("[[BATCH]]" + ";".join(moves)).encode())
    except: pass
PYEOF
