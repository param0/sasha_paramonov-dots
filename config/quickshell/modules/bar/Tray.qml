import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import "../../config"

Grid {
    id: root

    readonly property bool vertical: Appearance.bar.vertical

    rows: vertical ? -1 : 1
    columns: vertical ? 1 : -1
    rowSpacing: Appearance.spacing.normal
    columnSpacing: Appearance.spacing.normal

    Repeater {
        model: SystemTray.items

        delegate: Item {
            id: trayItem
            required property var modelData
            implicitWidth: Appearance.icon.size
            implicitHeight: Appearance.icon.size

            Image {
                anchors.fill: parent
                source: trayItem.modelData.icon
                sourceSize.width: Appearance.icon.size
                sourceSize.height: Appearance.icon.size
                smooth: true
            }

            TrayMenu {
                id: trayMenu
                trayItem: trayItem.modelData
                anchorItem: trayItem
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: function (mouse) {
                    // Middle click = quick-activate (open the app window).
                    if (mouse.button === Qt.MiddleButton) {
                        trayItem.modelData.activate();
                        return;
                    }
                    // Left/right = toggle the themed app menu (Open / Settings /
                    // Quit / …). Falls back to activate if there's no menu.
                    if (trayItem.modelData.hasMenu) {
                        trayMenu.open = !trayMenu.open;
                    } else if (mouse.button === Qt.LeftButton) {
                        trayItem.modelData.activate();
                    } else {
                        trayItem.modelData.secondaryActivate();
                    }
                }
            }
        }
    }
}
