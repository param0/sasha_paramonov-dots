import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import Qt.labs.folderlistmodel
import "../../config"
import "../../services"

PanelWindow {
    id: picker

    readonly property bool open: Visibilities.wallpaperPicker
    property bool render: false
    property bool shown: false

    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"
    visible: render

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    onOpenChanged: {
        if (open) {
            render = true;
            showT.restart();
        } else {
            shown = false;
            closeT.restart();
        }
    }
    Timer { id: showT; interval: 16; onTriggered: picker.shown = true }
    Timer { id: closeT; interval: 320; onTriggered: picker.render = false }

    GlobalShortcut {
        name: "wallpaper"
        description: "Toggle wallpaper picker"
        onPressed: Visibilities.wallpaperPicker = !Visibilities.wallpaperPicker
    }

    Item {
        anchors.fill: parent
        focus: picker.open
        Keys.onEscapePressed: Visibilities.wallpaperPicker = false

        // dim + click-away to close
        Rectangle {
            anchors.fill: parent
            color: Colours.shadow
            opacity: picker.shown ? 0.5 : 0
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            MouseArea { anchors.fill: parent; onClicked: Visibilities.wallpaperPicker = false }
        }

        Rectangle {
            id: panel
            anchors.centerIn: parent
            width: Math.min(parent.width - 140, 1120)
            height: Math.min(parent.height - 140, 720)
            radius: Appearance.radius.large
            color: Colours.surface

            opacity: picker.shown ? 1 : 0
            scale: picker.shown ? 1 : 0.95
            Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
            Behavior on scale {
                NumberAnimation {
                    duration: Appearance.anim.durations.expressiveDefaultSpatial
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Appearance.anim.curves.expressiveDefaultSpatial
                }
            }

            // swallow clicks on empty panel area (so they don't close the picker)
            MouseArea { anchors.fill: parent }

            Column {
                anchors.fill: parent
                anchors.margins: Appearance.spacing.large + 8
                spacing: Appearance.spacing.large

                Text {
                    text: I18n.s.wallpapers
                    color: Colours.text
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.sizeLarge
                    font.bold: true
                }

                GridView {
                    id: grid
                    width: parent.width
                    height: parent.height - implicitCellTitle
                    readonly property int implicitCellTitle: Appearance.font.sizeLarge + Appearance.spacing.large
                    clip: true
                    cellWidth: Math.floor(width / 4)
                    cellHeight: Math.floor(cellWidth * 9 / 16) + Appearance.spacing.normal
                    cacheBuffer: cellHeight * 4

                    model: FolderListModel {
                        folder: "file://" + Quickshell.env("HOME") + "/.config/wallpapers"
                        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.gif", "*.webp"]
                        showDirs: false
                        sortField: FolderListModel.Name
                    }

                    delegate: Item {
                        id: cell
                        required property string fileName
                        readonly property string filePath: Quickshell.env("HOME") + "/.config/wallpapers/" + cell.fileName
                        width: grid.cellWidth
                        height: grid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: Appearance.spacing.small
                            radius: Appearance.radius.normal
                            color: Colours.surfaceContainer
                            clip: true
                            border.width: thumbHover.hovered ? 3 : 0
                            border.color: Colours.primary

                            Behavior on border.width { NumberAnimation { duration: Appearance.anim.durationFast } }

                            Image {
                                anchors.fill: parent
                                source: "file://" + cell.filePath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                sourceSize.width: 400
                                sourceSize.height: 230
                            }

                            // filename label on hover
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: nameLabel.implicitHeight + Appearance.spacing.small
                                color: Colours.shadow
                                opacity: thumbHover.hovered ? 0.7 : 0
                                Behavior on opacity { NumberAnimation { duration: Appearance.anim.durationFast } }
                                Text {
                                    id: nameLabel
                                    anchors.centerIn: parent
                                    width: parent.width - Appearance.spacing.normal
                                    text: cell.fileName
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    color: "#ffffff"
                                    font.family: Appearance.font.family
                                    font.pixelSize: Appearance.font.sizeSmall
                                }
                            }

                            HoverHandler { id: thumbHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    Quickshell.execDetached(["bash",
                                        Quickshell.env("HOME") + "/.config/hypr/scripts/wallpapers/set.sh",
                                        cell.filePath]);
                                    Visibilities.wallpaperPicker = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
