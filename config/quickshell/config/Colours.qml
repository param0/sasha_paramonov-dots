pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Reads matugen colours from ~/.cache/quickshell-colors.json at runtime via a
// FileView (live-reloads on wallpaper change WITHOUT triggering a Quickshell
// config reload — the JSON lives outside the watched QML config dir).
Singleton {
    id: root

    property var c: ({})

    readonly property color background:       c.background       ?? "#1a1b26"
    readonly property color surface:          c.surface          ?? "#1f2130"
    readonly property color surfaceContainer: c.surfaceContainer ?? "#262838"
    readonly property color surfaceVariant:   c.surfaceVariant   ?? "#2f3145"

    readonly property color text:             c.text             ?? "#c0caf5"
    readonly property color subtext:          c.subtext          ?? "#9aa5ce"
    readonly property color outline:          c.outline          ?? "#414868"

    readonly property color primary:          c.primary          ?? "#7aa2f7"
    readonly property color primaryText:      c.primaryText      ?? "#1a1b26"
    readonly property color secondary:        c.secondary        ?? "#bb9af7"
    readonly property color tertiary:         c.tertiary         ?? "#7dcfff"
    readonly property color error:            c.error            ?? "#f7768e"
    readonly property color success:          c.success          ?? "#9ece6a"
    readonly property color warning:          c.warning          ?? "#e0af68"

    readonly property color shadow:           c.shadow           ?? "#000000"

    FileView {
        path: Quickshell.env("HOME") + "/.cache/quickshell-colors.json"
        watchChanges: true
        onLoaded: {
            try {
                root.c = JSON.parse(text());
            } catch (e) {
                // keep fallback defaults on parse error
            }
        }
        onFileChanged: reload()
    }
}
