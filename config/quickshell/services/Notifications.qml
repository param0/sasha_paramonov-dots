pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var notifications: []
    property int count: notifications.length

    // Poll mako for current notifications
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: listProc.running = true
    }

    Process {
        id: listProc
        command: ["makoctl", "list"]
        stdout: SplitParser {
            onRead: data => root.parseList(data)
        }
    }

    property string _buf: ""

    function parseList(line) {
        if (line.startsWith("Notification")) {
            if (_buf !== "") _parseOne(_buf);
            _buf = line;
        } else {
            _buf += "\n" + line;
        }
    }

    // Called after a small delay to process the last chunk
    Timer {
        interval: 200
        running: listProc.running === false
        repeat: false
        onTriggered: {
            if (root._buf !== "") {
                root._parseOne(root._buf);
                root._buf = "";
            }
        }
    }

    property var _pending: []

    // Called when listProc finishes
    Connections {
        target: listProc
        function onRunningChanged() {
            if (!listProc.running) {
                if (root._buf !== "") {
                    root._parseOne(root._buf);
                    root._buf = "";
                }
                root.notifications = root._pending;
                root._pending = [];
            }
        }
    }

    function _parseOne(block) {
        var lines = block.split("\n");
        var id = "";
        var summary = "";
        var body = "";
        var app = "";
        var urgency = "normal";

        for (var i = 0; i < lines.length; i++) {
            var l = lines[i].trim();
            if (l.indexOf("Notification") === 0) {
                id = l.replace("Notification ", "").replace(":", "").trim();
            } else if (l.indexOf("App name:") === 0) {
                app = l.replace("App name:", "").trim();
            } else if (l.indexOf("Urgency:") === 0) {
                urgency = l.replace("Urgency:", "").trim();
            } else if (l.indexOf("Summary:") === 0) {
                summary = l.replace("Summary:", "").trim();
            } else if (l.indexOf("Body:") === 0) {
                body = l.replace("Body:", "").trim();
            } else if (l.indexOf("Summary:") === -1 && summary === "" && l.length > 0 && id !== "") {
                // makoctl list format: "Notification N: <summary>" on first line
                var prefix = "Notification " + id + ": ";
                if (lines[i].indexOf(prefix) === 0) {
                    summary = lines[i].substring(prefix.length).trim();
                }
            }
        }

        if (id !== "") {
            root._pending.push({
                "id": id,
                "summary": summary || "(no summary)",
                "body": body,
                "app": app,
                "urgency": urgency
            });
        }
    }

    function dismiss(id) {
        Quickshell.execDetached(["makoctl", "dismiss", "-n", id]);
        notifications = notifications.filter(n => n.id !== id);
    }

    function dismissAll() {
        Quickshell.execDetached(["makoctl", "dismiss", "--all"]);
        notifications = [];
    }

    function restore() {
        Quickshell.execDetached(["makoctl", "restore"]);
    }
}
