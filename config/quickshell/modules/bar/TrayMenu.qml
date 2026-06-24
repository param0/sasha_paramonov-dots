import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../config"

// Themed renderer for a SystemTray item's DBus menu (matches quickshell style),
// instead of the native Qt platform menu.
PopupWindow {
    id: root

    property var trayItem
    property Item anchorItem
    property bool open: false

    readonly property var rootHandle: root.trayItem ? root.trayItem.menu : null
    property var currentHandle: rootHandle
    readonly property string pos: Appearance.bar.position

    onOpenChanged: if (!open) root.currentHandle = root.rootHandle   // reset drill-in on close

    QsMenuOpener { id: opener; menu: root.currentHandle }

    anchor.item: root.anchorItem
    anchor.rect.x: !root.anchorItem ? 0
                 : root.pos === "left"  ? root.anchorItem.width + 8
                 : root.pos === "right" ? -root.width - 8
                 : (root.anchorItem.width - root.width) / 2
    anchor.rect.y: !root.anchorItem ? 0
                 : root.pos === "top"    ? root.anchorItem.height + 8
                 : root.pos === "bottom" ? -root.height - 8
                 : 0

    implicitWidth: 240
    implicitHeight: bg.implicitHeight
    visible: root.open
    color: "transparent"

    // dismiss on click outside
    HyprlandFocusGrab {
        active: root.open
        windows: [root]
        onCleared: root.open = false
    }

    Rectangle {
        id: bg
        anchors.fill: parent
        implicitHeight: col.implicitHeight + Appearance.spacing.small
        radius: Appearance.radius.normal
        color: Colours.surfaceContainer
        border.width: 1
        border.color: Colours.outline

        Column {
            id: col
            width: parent.width
            padding: Appearance.spacing.small / 2 + 2
            spacing: 1

            // back row (only inside a submenu)
            Rectangle {
                visible: root.currentHandle !== root.rootHandle
                width: col.width - col.padding * 2
                height: 32
                radius: Appearance.radius.small
                color: backMa.containsMouse ? Colours.surfaceVariant : "transparent"
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Appearance.spacing.normal
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Appearance.spacing.small
                    Text { text: ""; color: Colours.subtext; font.family: Appearance.font.family; font.pixelSize: Appearance.font.sizeSmall; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Назад"; color: Colours.subtext; font.family: Appearance.font.family; font.pixelSize: Appearance.font.size; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: backMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.currentHandle = root.rootHandle }
            }

            Repeater {
                model: opener.children

                delegate: Item {
                    required property var modelData
                    width: col.width - col.padding * 2
                    height: modelData.isSeparator ? 9 : 34

                    // separator
                    Rectangle {
                        visible: modelData.isSeparator
                        anchors.centerIn: parent
                        width: parent.width - 8
                        height: 1
                        color: Colours.outline
                        opacity: 0.4
                    }

                    // entry
                    Rectangle {
                        visible: !modelData.isSeparator
                        anchors.fill: parent
                        radius: Appearance.radius.small
                        color: (ma.containsMouse && modelData.enabled) ? Colours.surfaceVariant : "transparent"

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: Appearance.spacing.normal
                            anchors.right: parent.right
                            anchors.rightMargin: Appearance.spacing.normal
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Appearance.spacing.small

                            // check / radio state
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.buttonType !== 0
                                text: modelData.checkState === 2 ? "" : ""
                                color: Colours.primary
                                font.family: Appearance.font.family
                                font.pixelSize: Appearance.font.sizeSmall
                                width: visible ? implicitWidth : 0
                            }

                            Image {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: modelData.icon != ""
                                source: modelData.icon
                                sourceSize.width: 16
                                sourceSize.height: 16
                                width: visible ? 16 : 0
                                height: 16
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: modelData.text
                                color: modelData.enabled ? Colours.text : Colours.subtext
                                font.family: Appearance.font.family
                                font.pixelSize: Appearance.font.size
                                elide: Text.ElideRight
                            }
                        }

                        // submenu chevron
                        Text {
                            visible: modelData.hasChildren
                            anchors.right: parent.right
                            anchors.rightMargin: Appearance.spacing.normal
                            anchors.verticalCenter: parent.verticalCenter
                            text: ""
                            color: Colours.subtext
                            font.family: Appearance.font.family
                            font.pixelSize: Appearance.font.sizeSmall
                        }

                        MouseArea {
                            id: ma
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: modelData.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.hasChildren) {
                                    root.currentHandle = modelData;
                                } else {
                                    modelData.triggered();
                                    root.open = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
