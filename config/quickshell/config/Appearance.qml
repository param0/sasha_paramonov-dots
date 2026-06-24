pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property QtObject font: QtObject {
        readonly property string family: "JetBrainsMono Nerd Font"
        readonly property string sans: family   // one font everywhere
        readonly property int size: 13
        readonly property int sizeSmall: 11
        readonly property int sizeLarge: 16
    }

    readonly property QtObject spacing: QtObject {
        readonly property int small: 6
        readonly property int normal: 10
        readonly property int large: 16
    }

    readonly property QtObject radius: QtObject {
        readonly property int small: 6
        readonly property int normal: 12
        readonly property int large: 20
        readonly property int full: 9999
    }

    // Uniform size for ALL status/tray glyphs & icons.
    readonly property QtObject icon: QtObject {
        readonly property int size: 17
    }

    readonly property QtObject bar: QtObject {
        id: bar

        // Where the bar lives: "top" | "bottom" | "left" | "right".
        // Mutable so a bar button can change it at runtime.
        property string position: "left"
        readonly property bool vertical: position === "left" || position === "right"

        readonly property int thickness: 38   // height when horizontal, width when vertical
        readonly property int margin: 20       // matches Hyprland gaps_out so the bar lines up with windows
    }

    readonly property QtObject anim: QtObject {
        readonly property int durationFast: 120
        readonly property int durationNormal: 220

        // Material 3 motion durations (matches caelestia)
        readonly property QtObject durations: QtObject {
            readonly property int small: 200
            readonly property int normal: 350
            readonly property int large: 500
            readonly property int expressiveFastSpatial: 350
            readonly property int expressiveDefaultSpatial: 500
            readonly property int expressiveEffects: 200
        }

        // Material 3 easing curves as Bezier splines (matches caelestia).
        // Use with: easing.type: Easing.BezierSpline; easing.bezierCurve: <curve>
        readonly property QtObject curves: QtObject {
            readonly property var standard: [0.2, 0, 0, 1, 1, 1]
            readonly property var standardAccel: [0.3, 0, 1, 1, 1, 1]
            readonly property var standardDecel: [0, 0, 0, 1, 1, 1]
            readonly property var emphasized: [0.05, 0, 0.133333, 0.06, 0.166666, 0.4, 0.208333, 0.82, 0.25, 1, 1, 1]
            readonly property var emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
            readonly property var emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
            readonly property var expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
            readonly property var expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
            readonly property var expressiveEffects: [0.34, 0.8, 0.34, 1, 1, 1]
        }
    }
}
