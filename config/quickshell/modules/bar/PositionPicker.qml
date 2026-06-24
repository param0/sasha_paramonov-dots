import Quickshell
import QtQuick
import "../../config"
import "../../services"

// Just the bar icon; the actual picker panel is a full-screen overlay
Text {
    id: root

    height: Appearance.icon.size
    verticalAlignment: Text.AlignVCenter
    text: ""
    color: (hover.hovered || Visibilities.positionPicker) ? Colours.primary : Colours.subtext
    font.family: Appearance.font.family
    font.pixelSize: Appearance.icon.size

    Behavior on color { ColorAnimation { duration: Appearance.anim.durationFast } }

    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: Visibilities.positionPicker = !Visibilities.positionPicker }
}
