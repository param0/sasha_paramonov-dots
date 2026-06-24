import subprocess, json, sys, time

def run(cmd):
    return subprocess.run(cmd, capture_output=True, text=True, timeout=0.5)

fw = None
for _ in range(10):
    try:
        r = run(['hyprctl','activewindow','-j'])
        w = json.loads(r.stdout)
        if w and w.get('address') and w.get('size',[0,0])[0] > 0:
            fw = w
            break
    except: pass
    time.sleep(0.05)

if not fw: sys.exit()

r = run(['hyprctl','monitors','-j'])
monitors = json.loads(r.stdout)
m = next((x for x in monitors if x.get('focused')), monitors[0])
cx = m['x'] + m['width']//2
cy = m['y'] + m['height']//2

dx = cx - (fw['at'][0] + fw['size'][0]//2)
dy = cy - (fw['at'][1] + fw['size'][1]//2)
if dx == 0 and dy == 0: sys.exit()

ws_id = fw.get('workspace',{}).get('id')
r = run(['hyprctl','clients','-j'])
moves = [
    f"dispatch movewindowpixel exact {w['at'][0]+dx} {w['at'][1]+dy},address:{w['address']}"
    for w in json.loads(r.stdout)
    if w.get('floating') and w.get('workspace',{}).get('id') == ws_id
]
if moves:
    subprocess.run(['hyprctl','--batch', ' ; '.join(moves)], capture_output=True, timeout=1)
