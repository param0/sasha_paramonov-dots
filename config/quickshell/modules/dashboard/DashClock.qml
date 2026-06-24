import Quickshell
import QtQuick
import "../../config"
import "../../services"

Column {
    id: root
    spacing: 2

    property string timeText: ""
    property string dateText: ""

    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            const n = new Date();
            root.timeText = Qt.formatDateTime(n, "HH:mm");
            root.dateText = I18n.fmtDate(n, "dddd, d MMMM");
        }
    }

    Text {
        text: root.timeText
        color: Colours.text
        font.family: Appearance.font.family
        font.pixelSize: 52
        font.bold: true
    }
    Text {
        text: root.dateText
        color: Colours.subtext
        font.family: Appearance.font.family
        font.pixelSize: 15
    }
}
