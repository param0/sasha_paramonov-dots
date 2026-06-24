import Quickshell
import QtQuick
import "../../config"

Item {
    id: root
    property string icon: ""
    property real value: 0
    signal moved(real v)

    height: 30

    Text {
        id: ic
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Appearance.icon.size
        horizontalAlignment: Text.AlignHCenter
        text: root.icon
        color: Colours.text
        font.family: Appearance.font.family
        font.pixelSize: Appearance.icon.size
    }
    Rectangle {
        id: track
        anchors.left: ic.right
        anchors.leftMargin: Appearance.spacing.normal
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 8
        radius: Appearance.radius.full
        color: Colours.surfaceVariant

        Rectangle {
            id: fill
            height: parent.height
            radius: parent.radius
            width: parent.width * Math.max(0, Math.min(1, root.value))
            color: Colours.primary
        }
        Rectangle {
            width: 16; height: 16
            radius: 8
            color: Colours.primary
            border.width: 3
            border.color: Colours.surface
            anchors.verticalCenter: parent.verticalCenter
            x: Math.max(0, Math.min(parent.width - width, fill.width - width / 2))
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8
            onPressed: mouse => root.moved(Math.max(0, Math.min(1, mouse.x / track.width)))
            onPositionChanged: mouse => root.moved(Math.max(0, Math.min(1, mouse.x / track.width)))
        }
    }
}
