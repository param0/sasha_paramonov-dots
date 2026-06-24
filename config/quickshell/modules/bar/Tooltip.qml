import Quickshell
import QtQuick
import "../../config"

// Small hover tooltip anchored next to `target`, placed on the side away from
// the bar's edge (right for a left bar, below for a top bar, etc.).
PopupWindow {
    id: root

    property Item target
    property string text: ""
    property bool show: false
    readonly property string pos: Appearance.bar.position

    anchor.item: root.target
    anchor.rect.x: root.pos === "left"  ? (root.target ? root.target.width : 0) + 10
                 : root.pos === "right" ? -root.width - 10
                 : (root.target ? (root.target.width - root.width) / 2 : 0)
    anchor.rect.y: root.pos === "top"    ? (root.target ? root.target.height : 0) + 10
                 : root.pos === "bottom" ? -root.height - 10
                 : (root.target ? (root.target.height - root.height) / 2 : 0)

    implicitWidth: bubble.implicitWidth
    implicitHeight: bubble.implicitHeight
    visible: root.show && root.text.length > 0
    color: "transparent"

    Rectangle {
        id: bubble
        anchors.fill: parent
        implicitWidth: label.implicitWidth + 22
        implicitHeight: label.implicitHeight + 12
        radius: Appearance.radius.small
        color: Colours.surfaceContainer
        border.width: 1
        border.color: Colours.outline

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: Colours.text
            font.family: Appearance.font.family
            font.pixelSize: Appearance.font.sizeSmall
        }
    }
}
