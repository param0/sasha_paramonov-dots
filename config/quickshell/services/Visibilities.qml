pragma Singleton

import Quickshell

// Shared UI visibility state (toggled by bar clicks & global shortcuts).
Singleton {
    id: root

    property bool dashboard: false
    property bool positionPicker: false
    property bool wallpaperPicker: false
}
