import Quickshell
import QtQuick
import "../../config"
import "../../services"

Column {
    id: root
    spacing: Appearance.spacing.normal

    function fmt(used, total) { return used.toFixed(1) + " / " + total.toFixed(1) + " GiB"; }

    Repeater {
        model: [
            { "label": "CPU",  "ratio": SystemStats.cpu,       "val": Math.round(SystemStats.cpu * 100) + "%" },
            { "label": "RAM",  "ratio": SystemStats.memRatio,  "val": root.fmt(SystemStats.memUsed, SystemStats.memTotal) },
            { "label": "TEMP", "ratio": Math.min(1, SystemStats.temp / 100), "val": Math.round(SystemStats.temp) + "°C" },
            { "label": "DISK", "ratio": SystemStats.diskRatio, "val": root.fmt(SystemStats.diskUsed, SystemStats.diskTotal) }
        ]
        delegate: Item {
            required property var modelData
            width: root.width
            height: 34

            Text {
                id: lbl
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 50
                text: modelData.label
                color: Colours.subtext
                font.family: Appearance.font.family
                font.pixelSize: Appearance.font.sizeSmall
            }
            Rectangle {
                id: track
                anchors.left: lbl.right
                anchors.right: valTxt.left
                anchors.rightMargin: Appearance.spacing.normal
                anchors.verticalCenter: parent.verticalCenter
                height: 8
                radius: Appearance.radius.full
                color: Colours.surfaceVariant
                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * Math.max(0, Math.min(1, modelData.ratio))
                    color: modelData.ratio > 0.85 ? Colours.error : Colours.primary
                    Behavior on width { NumberAnimation { duration: Appearance.anim.durationNormal } }
                }
            }
            Text {
                id: valTxt
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 110
                horizontalAlignment: Text.AlignRight
                text: modelData.val
                color: Colours.text
                font.family: Appearance.font.family
                font.pixelSize: Appearance.font.sizeSmall
            }
        }
    }
}
