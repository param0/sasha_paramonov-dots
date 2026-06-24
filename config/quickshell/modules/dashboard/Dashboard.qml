import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../../config"
import "../../services"

PanelWindow {
    id: dash

    readonly property bool open: Visibilities.dashboard
    property bool render: false
    property bool shown: false   // drives the entrance/exit animation (toggled a frame after render)
    readonly property string pos: Appearance.bar.position
    readonly property int barEdge: Appearance.bar.margin + Appearance.bar.thickness
    // tiny overlap hides the seam without covering the bar's centred icons
    readonly property int reserve: barEdge - 4
    readonly property int r: Appearance.radius.large

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1   // cover the FULL output, ignoring the bar's reserved zone
    color: "transparent"
    visible: render

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onOpenChanged: {
        if (open) {
            render = true;        // map the window first (card starts hidden)
            showT.restart();      // then animate it in on the next frame
        } else {
            shown = false;        // animate out
            closeT.restart();     // unmap after the animation finishes
        }
    }
    Timer { id: showT; interval: 16; onTriggered: dash.shown = true }
    Timer { id: closeT; interval: Appearance.anim.durations.expressiveDefaultSpatial + 40; onTriggered: dash.render = false }

    GlobalShortcut {
        name: "dashboard"
        description: "Toggle dashboard"
        onPressed: Visibilities.dashboard = !Visibilities.dashboard
    }

    Item {
        anchors.fill: parent
        focus: dash.open
        Keys.onEscapePressed: Visibilities.dashboard = false

        // Click anywhere outside the card to close (no dim — keeps the
        // bar+card merge looking consistent).
        MouseArea {
            anchors.fill: parent
            onClicked: Visibilities.dashboard = false
        }

        // ── Card: bulges out of the bar (square corners on the bar side) ──
        Rectangle {
            id: card

            width: 760
            height: 730
            color: Colours.surface

            // square the corners facing the bar so it reads as fused to it
            topLeftRadius: (dash.pos === "left" || dash.pos === "top") ? 0 : dash.r
            bottomLeftRadius: (dash.pos === "left" || dash.pos === "bottom") ? 0 : dash.r
            topRightRadius: (dash.pos === "right" || dash.pos === "top") ? 0 : dash.r
            bottomRightRadius: (dash.pos === "right" || dash.pos === "bottom") ? 0 : dash.r

            x: dash.pos === "left"  ? dash.reserve
             : dash.pos === "right" ? parent.width - width - dash.reserve
             : (parent.width - width) / 2
            y: dash.pos === "top"    ? dash.reserve
             : dash.pos === "bottom" ? parent.height - height - dash.reserve
             : (parent.height - height) / 2

            opacity: dash.shown ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveEffects
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveEffects
                }
            }

            // Grow out of the bar along the perpendicular axis ONLY, with the
            // origin on the bar edge — so the edge touching the bar stays flush
            // and full-length through the whole animation (the merge never
            // "breaks" mid-transition, even with the springy overshoot).
            transform: Scale {
                origin.x: dash.pos === "right" ? card.width : 0
                origin.y: dash.pos === "bottom" ? card.height : (dash.pos === "top" ? 0 : card.height / 2)
                xScale: Appearance.bar.vertical ? (dash.shown ? 1 : 0.55) : 1
                yScale: Appearance.bar.vertical ? 1 : (dash.shown ? 1 : 0.55)
                Behavior on xScale {
                    NumberAnimation {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }
                Behavior on yScale {
                    NumberAnimation {
                        duration: Appearance.anim.durations.expressiveDefaultSpatial
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                    }
                }
            }

            // ── content ──
            Column {
                anchors.fill: parent
                anchors.margins: Appearance.spacing.large + 8
                spacing: Appearance.spacing.large + 4

                // header: clock + power
                Item {
                    width: parent.width
                    height: 64
                    DashClock { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                    DashPower { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                }

                // media + calendar (row grows to fit the taller of the two)
                Row {
                    width: parent.width
                    spacing: Appearance.spacing.large

                    DashMedia {
                        width: 380
                        height: 170
                    }
                    DashCalendar {
                        width: parent.width - 380 - Appearance.spacing.large
                    }
                }

                DashResources { width: parent.width }

                DashControls { width: parent.width }
            }
        }
    }
}
