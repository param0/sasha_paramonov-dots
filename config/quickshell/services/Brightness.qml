pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string device: ""
    property int max: 1
    property int current: 0
    readonly property real value: max > 0 ? current / max : 0

    // Discover the backlight device once (e.g. nvidia_0, intel_backlight).
    Process {
        running: true
        command: ["sh", "-c", "basename \"$(ls -d /sys/class/backlight/*/ 2>/dev/null | head -1)\""]
        stdout: StdioCollector {
            onStreamFinished: root.device = text.trim()
        }
    }

    FileView {
        path: root.device ? `/sys/class/backlight/${root.device}/max_brightness` : ""
        onLoaded: root.max = parseInt(text()) || 1
    }

    FileView {
        id: curView
        path: root.device ? `/sys/class/backlight/${root.device}/brightness` : ""
        watchChanges: true
        onLoaded: root.current = parseInt(text()) || 0
        onFileChanged: reload()
    }

    function setValue(v) {
        const clamped = Math.max(0, Math.min(1, v));
        setProc.command = ["brightnessctl", "s", Math.round(clamped * 100) + "%"];
        setProc.running = true;
    }

    Process { id: setProc }
}
