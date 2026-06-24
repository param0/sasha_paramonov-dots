import Quickshell
import QtQuick
import "../../config"

Row {
    id: root
    spacing: Appearance.spacing.normal

    Repeater {
        model: [
            { "icon": "",   "cmd": "loginctl lock-session" },
            { "icon": "", "cmd": "hyprctl dispatch exit" },
            { "icon": "", "cmd": "systemctl reboot" },
            { "icon": "",  "cmd": "systemctl poweroff" }
        ]
        delegate: Rectangle {
            required property var modelData
            width: 42; height: 42
            radius: Appearance.radius.normal
            color: ma.containsMouse ? Colours.surfaceVariant : Colours.surfaceContainer

            Behavior on color { ColorAnimation { duration: Appearance.anim.durationFast } }

            Text {
                anchors.centerIn: parent
                text: modelData.icon
                color: ma.containsMouse ? Colours.primary : Colours.text
                font.family: Appearance.font.family
                font.pixelSize: Appearance.icon.size
            }
            MouseArea {
                id: ma
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Quickshell.execDetached(["sh", "-c", modelData.cmd])
            }
        }
    }
}
