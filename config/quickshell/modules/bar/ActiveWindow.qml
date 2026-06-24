import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../../config"

Text {
    id: root

    text: Hyprland.activeToplevel?.title ?? "Desktop"
    color: Colours.subtext
    font.family: Appearance.font.sans
    font.pixelSize: Appearance.font.size
    elide: Text.ElideRight
    maximumLineCount: 1
}
