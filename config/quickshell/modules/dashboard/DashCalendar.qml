import Quickshell
import QtQuick
import "../../config"
import "../../services"

Column {
    id: root
    spacing: Appearance.spacing.small

    property int today: 0
    property int curMonth: 0
    property string monthLabel: ""
    property var days: []

    Component.onCompleted: {
        const d = new Date();
        root.today = d.getDate();
        root.curMonth = d.getMonth();
        root.monthLabel = I18n.fmtDate(d, "MMMM yyyy");
        const first = new Date(d.getFullYear(), d.getMonth(), 1).getDay();
        const offset = (first + 6) % 7;
        const dim = new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate();
        const cells = [];
        for (let i = 0; i < offset; i++) cells.push(0);
        for (let day = 1; day <= dim; day++) cells.push(day);
        root.days = cells;
    }

    Text {
        text: root.monthLabel
        color: Colours.text
        font.family: Appearance.font.family
        font.pixelSize: Appearance.font.size
        font.bold: true
    }

    Grid {
        columns: 7
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: I18n.s.weekdays
            delegate: Item {
                required property var modelData
                width: 34; height: 22
                Text {
                    anchors.centerIn: parent
                    text: modelData
                    color: Colours.subtext
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.sizeSmall
                }
            }
        }

        Repeater {
            model: root.days
            delegate: Item {
                required property var modelData
                width: 34; height: 30
                Rectangle {
                    anchors.centerIn: parent
                    width: 28; height: 28
                    radius: Appearance.radius.full
                    visible: modelData === root.today
                    color: Colours.primary
                }
                Text {
                    anchors.centerIn: parent
                    visible: modelData > 0
                    text: modelData > 0 ? modelData : ""
                    color: modelData === root.today ? Colours.primaryText : Colours.text
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.sizeSmall
                }
            }
        }
    }
}
