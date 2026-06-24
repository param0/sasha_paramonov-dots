#!/usr/bin/env python3
import sys, threading, time, json, os, socket

speed = float(sys.argv[3]) if len(sys.argv) > 3 else 1.6

sig = os.environ.get('HYPRLAND_INSTANCE_SIGNATURE', '')
rt = os.environ.get('XDG_RUNTIME_DIR', f'/run/user/{os.getuid()}')
CMD_SOCK = f"{rt}/hypr/{sig}/.socket.sock"
EV_SOCK = f"{rt}/hypr/{sig}/.socket2.sock"

SIZE_FILE = "/tmp/hypr-sizes.json"
DRAG_STATE = "/tmp/infinite-drag-state"
MODE_STATE = "/tmp/hypr-desktop-mode"

def ask_hypr(cmd):
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(CMD_SOCK)
            s.sendall(cmd.encode())
            data = b""
            while True:
                chunk = s.recv(8192)
                if not chunk: break
                data += chunk
            return json.loads(data.decode('utf-8'))
    except: return None

def fast_dispatch(cmd_string):
    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
            s.connect(CMD_SOCK)
            s.sendall(cmd_string.encode())
    except: pass

drag_mode = False
drag_last = [None, None]
floating_cache = []
cache_lock = threading.Lock()

class_map = {}
size_map = {}

def update_floating():
    global floating_cache
    try:
        ws_info = ask_hypr("j/activeworkspace")
        ws_id = ws_info.get('id', 1) if ws_info else 1
        clients = ask_hypr("j/clients")
        if clients:
            with cache_lock:
                floating_cache = [{'addr': c['address'], 'x': c['at'][0], 'y': c['at'][1]}
                                  for c in clients if c.get('floating') and c.get('workspace',{}).get('id') == ws_id]
    except: pass

def size_poller():
    while True:
        clients = ask_hypr("j/clients")
        if clients:
            for c in clients:
                if c.get('size',[0])[0] > 50:
                    class_map[c['address']] = c['class']
                    size_map[c['address']] = c['size']
        time.sleep(0.5)

def on_close(addr_hex):
    addr = '0x' + addr_hex
    cls, sz = class_map.get(addr), size_map.get(addr)
    if cls and sz:
        try:
            d = json.loads(open(SIZE_FILE).read()) if os.path.exists(SIZE_FILE) else {}
            d[cls] = sz
            open(SIZE_FILE, 'w').write(json.dumps(d))
        except: pass

def on_open(addr_hex):
    time.sleep(0.12)
    addr = '0x' + addr_hex
    try:
        mode = open(MODE_STATE).read().strip() if os.path.exists(MODE_STATE) else "tiling"
        if mode != 'infinite':
            return

        clients = ask_hypr("j/clients")
        w = next((c for c in clients if c['address'] == addr), None) if clients else None
        if not w: return

        if not w.get('floating'):
            fast_dispatch(f"dispatch togglefloating address:{addr}")

        cls = w.get('class')
        d = json.loads(open(SIZE_FILE).read()) if os.path.exists(SIZE_FILE) else {}
        if cls in d:
            sz = d[cls]
            fast_dispatch(f"dispatch resizewindowpixel exact {sz[0]} {sz[1]},address:{addr}")

        update_floating()
    except: pass

def socket_listener():
    while True:
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(EV_SOCK)
                buf = ''
                while True:
                    data = s.recv(8192).decode('utf-8', errors='ignore')
                    if not data: break
                    buf += data
                    while '\n' in buf:
                        line, buf = buf.split('\n', 1)
                        if line.startswith('openwindow>>'):
                            threading.Thread(target=on_open, args=(line.split('>>')[1].split(',')[0],)).start()
                        elif line.startswith('closewindow>>'):
                            threading.Thread(target=on_close, args=(line.split('>>')[1],)).start()
        except: time.sleep(2)

def drag_reader():
    global drag_mode
    prev = 'end'
    while True:
        try:
            state = open(DRAG_STATE).read().strip() if os.path.exists(DRAG_STATE) else 'end'
            if state != prev:
                if state == 'start':
                    update_floating()
                    drag_last[0], drag_last[1] = None, None
                    drag_mode = True
                else:
                    drag_mode = False
                prev = state
        except: pass
        time.sleep(0.01)

threading.Thread(target=socket_listener, daemon=True).start()
threading.Thread(target=drag_reader, daemon=True).start()
threading.Thread(target=size_poller, daemon=True).start()

while True:
    time.sleep(0.008)
    if not drag_mode: continue
    
    pos = ask_hypr("j/cursorpos")
    if not pos: continue
    cx, cy = pos.get('x', 0), pos.get('y', 0)
    
    if drag_last[0] is None:
        drag_last[0], drag_last[1] = cx, cy
        continue
        
    dx = cx - drag_last[0]
    dy = cy - drag_last[1]
    
    if dx == 0 and dy == 0: continue
    
    drag_last[0], drag_last[1] = cx, cy
    idx, idy = int(round(dx * speed)), int(round(dy * speed))
    
    if idx == 0 and idy == 0: continue

    with cache_lock:
        moves = []
        updated = []
        for w in floating_cache:
            nx = w['x'] + idx
            ny = w['y'] + idy
            moves.append(f"dispatch movewindowpixel exact {nx} {ny},address:{w['addr']}")
            updated.append({'addr': w['addr'], 'x': nx, 'y': ny})
        floating_cache = updated
        
    if moves:
        fast_dispatch("[[BATCH]]" + ";".join(moves))
