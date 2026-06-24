import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config"
import "../../services"

PanelWindow {
    id: overlay

    readonly property bool open: Visibilities.positionPicker
    property bool render: false
    property bool shown: false
    readonly property string pos: Appearance.bar.position
    // Hug the bar's outer edge (slight overlap to read as attached).
    readonly property int reserve: Appearance.bar.margin + Appearance.bar.thickness - 6
    readonly property int pad: Appearance.bar.margin

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"
    visible: render

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onOpenChanged: {
        if (open) {
            render = true;
            showT.restart();
        } else {
            shown = false;
            closeT.restart();
        }
    }
    Timer { id: showT; interval: 16; onTriggered: overlay.shown = true }
    Timer { id: closeT; interval: Appearance.anim.durations.expressiveDefaultSpatial + 40; onTriggered: overlay.render = false }

    Item {
        anchors.fill: parent
        focus: overlay.open
        Keys.onEscapePressed: Visibilities.positionPicker = false

        // click-away to close (no dim — this is a light popup)
        MouseArea {
            anchors.fill: parent
            onClicked: Visibilities.positionPicker = false
        }

        Rectangle {
            id: panel

            width: 180
            height: col.implicitHeight + Appearance.spacing.normal * 2
            radius: Appearance.radius.normal
            color: Colours.surfaceContainer
            border.width: 1
            border.color: Colours.outline

            // Numeric placement near the bar's edge (no anchor toggling).
            x: overlay.pos === "left"  ? overlay.reserve
             : overlay.pos === "right" ? parent.width - width - overlay.reserve
             : parent.width - width - overlay.pad
            y: overlay.pos === "top"    ? overlay.reserve
             : overlay.pos === "bottom" ? parent.height - height - overlay.reserve
             : parent.height - height - overlay.pad

            opacity: overlay.shown ? 1 : 0
            scale: overlay.shown ? 1 : 0.85
            transformOrigin: overlay.pos === "left"  ? Item.Left
                           : overlay.pos === "right" ? Item.Right
                           : overlay.pos === "top"   ? Item.Top : Item.Bottom

            Behavior on opacity {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveEffects
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveEffects
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            Column {
                id: col
                anchors.centerIn: parent
                width: parent.width - Appearance.spacing.normal * 2
                spacing: 2

                Repeater {
                    model: [
                        { "label": I18n.s.posTop,    "val": "top" },
                        { "label": I18n.s.posBottom, "val": "bottom" },
                        { "label": I18n.s.posLeft,   "val": "left" },
                        { "label": I18n.s.posRight,  "val": "right" }
                    ]

                    delegate: Rectangle {
                        id: opt
                        required property var modelData
                        readonly property bool current: Appearance.bar.position === modelData.val

                        width: col.width
                        height: 36
                        radius: Appearance.radius.small
                        color: mouse.containsMouse ? Colours.surfaceVariant
                             : (current ? Colours.primary : "transparent")

                        Behavior on color { ColorAnimation { duration: Appearance.anim.durationFast } }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: Appearance.spacing.normal
                            anchors.verticalCenter: parent.verticalCenter
                            text: opt.modelData.label
                            color: opt.current ? Colours.primaryText : Colours.text
                            font.family: Appearance.font.sans
                            font.pixelSize: Appearance.font.size
                        }

                        MouseArea {
                            id: mouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Appearance.bar.position = opt.modelData.val;
                                Visibilities.positionPicker = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
