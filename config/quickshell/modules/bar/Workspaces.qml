import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../config"

Grid {
    id: root

    readonly property bool vertical: Appearance.bar.vertical

    // Single row (horizontal) or single column (vertical).
    rows: vertical ? -1 : 1
    columns: vertical ? 1 : -1
    rowSpacing: Appearance.spacing.small
    columnSpacing: Appearance.spacing.small

    // Scroll over the workspaces to switch them (down/right = next, up/left = prev).
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => Hyprland.dispatch(event.angleDelta.y < 0 || event.angleDelta.x < 0
                                            ? "workspace e+1" : "workspace e-1")
    }

    Repeater {
        // Drop special workspaces (id < 0) and keep them ordered by id.
        model: [...Hyprland.workspaces.values]
            .filter(w => w.id >= 1)
            .sort((a, b) => a.id - b.id)

        delegate: Rectangle {
            id: pill
            required property var modelData

            readonly property bool isFocused: Hyprland.focusedWorkspace?.id === modelData.id

            // The pill grows along the bar's main axis when focused.
            implicitWidth: root.vertical ? 10 : (isFocused ? 28 : 10)
            implicitHeight: root.vertical ? (isFocused ? 28 : 10) : 10
            radius: Appearance.radius.full
            color: isFocused ? Colours.primary
                 : (modelData.active ? Colours.secondary : Colours.surfaceVariant)

            Behavior on implicitWidth {
                NumberAnimation { duration: Appearance.anim.durationNormal; easing.type: Easing.OutCubic }
            }
            Behavior on implicitHeight {
                NumberAnimation { duration: Appearance.anim.durationNormal; easing.type: Easing.OutCubic }
            }
            Behavior on color {
                ColorAnimation { duration: Appearance.anim.durationFast }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Hyprland.dispatch("workspace " + pill.modelData.id)
            }
        }
    }
}
