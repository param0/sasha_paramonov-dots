pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Lightweight system metrics polled from /proc, /sys and `df`.
Singleton {
    id: root

    property real cpu: 0          // 0..1
    property real memUsed: 0      // GiB
    property real memTotal: 0     // GiB
    readonly property real memRatio: memTotal > 0 ? memUsed / memTotal : 0
    property real temp: 0         // °C
    property real diskUsed: 0     // GiB
    property real diskTotal: 0    // GiB
    readonly property real diskRatio: diskTotal > 0 ? diskUsed / diskTotal : 0

    property real _prevTotal: 0
    property real _prevIdle: 0

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
            tempFile.reload();
            dfProc.running = true;
        }
    }

    // ── CPU ── /proc/stat first line: cpu user nice system idle iowait ...
    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: {
            const line = text().split("\n")[0];          // "cpu  a b c d e ..."
            const p = line.trim().split(/\s+/).slice(1).map(Number);
            if (p.length < 5) return;
            const idle = p[3] + (p[4] || 0);
            const total = p.reduce((a, b) => a + b, 0);
            const dTotal = total - root._prevTotal;
            const dIdle = idle - root._prevIdle;
            if (dTotal > 0 && root._prevTotal > 0)
                root.cpu = Math.max(0, Math.min(1, 1 - dIdle / dTotal));
            root._prevTotal = total;
            root._prevIdle = idle;
        }
    }

    // ── Memory ── /proc/meminfo (kB)
    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const get = k => {
                const m = t.match(new RegExp(k + ":\\s+(\\d+)"));
                return m ? parseInt(m[1]) : 0;
            };
            const total = get("MemTotal");
            const avail = get("MemAvailable");
            root.memTotal = total / 1048576;                 // kB -> GiB
            root.memUsed = (total - avail) / 1048576;
        }
    }

    // ── Temperature ── first thermal zone (°milliC)
    FileView {
        id: tempFile
        path: "/sys/class/thermal/thermal_zone0/temp"
        onLoaded: {
            const v = parseInt(text());
            if (!isNaN(v)) root.temp = v / 1000;
        }
    }

    // ── Disk ── df on root filesystem
    Process {
        id: dfProc
        command: ["sh", "-c", "df -B1 --output=used,size / | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(/\s+/).map(Number);
                if (p.length >= 2) {
                    root.diskUsed = p[0] / 1073741824;       // bytes -> GiB
                    root.diskTotal = p[1] / 1073741824;
                }
            }
        }
    }
}
