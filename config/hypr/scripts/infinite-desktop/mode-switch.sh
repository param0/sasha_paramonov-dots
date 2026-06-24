#!/usr/bin/env bash
MODE=$1
STATE="/tmp/hypr-desktop-mode"
WS_MODES="/tmp/hypr-ws-modes.json"
TILE_SNAP="/tmp/hypr-tile-snapshot.json"
MODE_CONF="$HOME/.config/hypr/configs/mode.conf"
CURRENT=$(cat "$STATE" 2>/dev/null || echo "tiling")
[ "$MODE" = "$CURRENT" ] && exit 0

exec 9>/tmp/mode-switch.lock
flock -n 9 || exit 0

WS=$(hyprctl activeworkspace -j 2>/dev/null | python3 -c "import json,sys;print(json.load(sys.stdin)['id'])" 2>/dev/null || echo "1")
python3 -c "
import json
d={}
try: d=json.load(open('$WS_MODES'))
except: pass
d['$WS']='$MODE'
json.dump(d,open('$WS_MODES','w'))
"

if [ "$MODE" = "infinite" ]; then
    echo "infinite" > "$STATE"

    python3 << 'PYEOF'
import json, subprocess
r = subprocess.run(['hyprctl','activeworkspace','-j'], capture_output=True, text=True)
ws_id = json.loads(r.stdout)['id']
r = subprocess.run(['hyprctl','clients','-j'], capture_output=True, text=True)
tiled = [w for w in json.loads(r.stdout)
         if not w.get('floating') and w.get('workspace',{}).get('id') == ws_id]
tiled.sort(key=lambda w: (w['at'][1], w['at'][0]))
snap = [{'address': w['address'], 'at': w['at'], 'size': w['size']} for w in tiled]
try: existing = json.load(open('/tmp/hypr-tile-snapshot.json'))
except: existing = {}
existing[str(ws_id)] = snap
json.dump(existing, open('/tmp/hypr-tile-snapshot.json','w'))
PYEOF

    echo 'windowrulev2 = float,class:^(.*)$' > "$MODE_CONF"
    hyprctl reload

    python3 << 'PYEOF'
import json, subprocess, time
saved = {}
try: saved = json.load(open('/tmp/hypr-float-pos.json'))
except: pass
r = subprocess.run(['hyprctl','activeworkspace','-j'], capture_output=True, text=True)
ws_id = json.loads(r.stdout)['id']
r = subprocess.run(['hyprctl','clients','-j'], capture_output=True, text=True)
clients = [w for w in json.loads(r.stdout)
           if w.get('workspace',{}).get('id') == ws_id and not w.get('floating')]
procs = [subprocess.Popen(['hyprctl','dispatch','togglefloating',f'address:{w["address"]}'],
                          stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) for w in clients]
for p in procs: p.wait()
time.sleep(0.06)
r = subprocess.run(['hyprctl','clients','-j'], capture_output=True, text=True)
for w in json.loads(r.stdout):
    addr = w['address']
    if addr in saved:
        x,y = saved[addr]['at']; ww,wh = saved[addr]['size']
        subprocess.Popen(['hyprctl','dispatch','movewindowpixel',f'exact {x} {y},address:{addr}'],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.Popen(['hyprctl','dispatch','resizewindowpixel',f'exact {ww} {wh},address:{addr}'],
                        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
PYEOF

else
    echo "tiling" > "$STATE"
    echo 'end' > /tmp/infinite-drag-state

    python3 << 'PYEOF'
import json, subprocess, time

r = subprocess.run(['hyprctl','activeworkspace','-j'], capture_output=True, text=True)
ws_id = json.loads(r.stdout)['id']
r = subprocess.run(['hyprctl','clients','-j'], capture_output=True, text=True)
clients = [w for w in json.loads(r.stdout)
           if w.get('floating') and not w.get('pinned') and w.get('workspace',{}).get('id') == ws_id]

# сохраняем float-позиции (для следующего входа в infinite)
saved = {w['address']: {'at': w['at'], 'size': w['size']} for w in clients}
json.dump(saved, open('/tmp/hypr-float-pos.json','w'))

snap = []
try:
    snaps = json.load(open('/tmp/hypr-tile-snapshot.json'))
    snap = snaps.get(str(ws_id), [])
except: pass

current_addrs = {w['address'] for w in clients}
snap_addrs = [s['address'] for s in snap]
same_set = set(snap_addrs) == current_addrs and len(snap_addrs) > 0

ordered = [a for a in snap_addrs if a in current_addrs] + \
          [a for a in current_addrs if a not in snap_addrs]
size_map = {s['address']: s['size'] for s in snap}

for addr in ordered:
    subprocess.run(['hyprctl','dispatch','focuswindow', f'address:{addr}'], capture_output=True, timeout=0.3)
    time.sleep(0.02)
    subprocess.run(['hyprctl','dispatch','togglefloating', f'address:{addr}'], capture_output=True, timeout=0.3)
    time.sleep(0.03)

# Размеры форсируем ТОЛЬКО если набор окон не менялся — иначе ломает dwindle-дерево
if same_set:
    time.sleep(0.1)
    for _ in range(2):
        for addr in ordered:
            if addr in size_map:
                w, h = size_map[addr]
                subprocess.run(['hyprctl','dispatch','resizewindowpixel',
                                f'exact {w} {h},address:{addr}'], capture_output=True, timeout=0.3)
        time.sleep(0.05)
PYEOF

    echo '' > "$MODE_CONF"
    hyprctl reload
fi
