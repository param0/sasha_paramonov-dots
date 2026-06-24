import Quickshell
import QtQuick
import "../../config"
import "../../services"

Item {
    id: root

    readonly property bool vertical: Appearance.bar.vertical

    HoverHandler { cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: Visibilities.dashboard = !Visibilities.dashboard }

    property string hh: ""
    property string mm: ""
    property string dateText: ""

    implicitWidth: vertical ? col.implicitWidth : row.implicitWidth
    implicitHeight: vertical ? col.implicitHeight : row.implicitHeight

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date();
            root.hh = Qt.formatDateTime(now, "HH");
            root.mm = Qt.formatDateTime(now, "mm");
            root.dateText = I18n.fmtDate(now, "ddd, dd MMM");
        }
    }

    // ── Horizontal ────────────────────────────────────────
    Row {
        id: row
        visible: !root.vertical
        anchors.centerIn: parent
        spacing: Appearance.spacing.small

        Text {
            text: ""
            color: Colours.primary
            font.family: Appearance.font.family
            font.pixelSize: Appearance.icon.size
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: root.hh + ":" + root.mm
            color: Colours.text
            font.family: Appearance.font.family
            font.pixelSize: Appearance.font.size
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: "·  " + root.dateText
            color: Colours.subtext
            font.family: Appearance.font.family
            font.pixelSize: Appearance.font.size
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── Vertical ──────────────────────────────────────────
    Column {
        id: col
        visible: root.vertical
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.hh
            color: Colours.text
            font.family: Appearance.font.family
            font.pixelSize: Appearance.font.size
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.mm
            color: Colours.subtext
            font.family: Appearance.font.family
            font.pixelSize: Appearance.font.size
        }
    }
}
