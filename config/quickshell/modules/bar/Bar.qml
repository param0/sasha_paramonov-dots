import Quickshell
import Quickshell.Wayland
import QtQuick
import "../../config"

PanelWindow {
    id: bar

    required property var modelData

    readonly property bool vertical: Appearance.bar.vertical
    readonly property string pos: Appearance.bar.position

    screen: modelData

    anchors {
        top:    pos === "top"
        bottom: pos === "bottom"
        left:   pos === "left"
        right:  pos === "right"
    }

    exclusiveZone: Appearance.bar.thickness + Appearance.bar.margin
    implicitWidth:  vertical ? Appearance.bar.thickness : 0
    implicitHeight: vertical ? 0 : Appearance.bar.thickness
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        anchors.fill: parent
        color: Colours.surface
        opacity: 0.92

        topLeftRadius:     pos === "top"    || pos === "left"  ? 0 : Appearance.radius.normal
        topRightRadius:    pos === "top"    || pos === "right" ? 0 : Appearance.radius.normal
        bottomLeftRadius:  pos === "bottom" || pos === "left"  ? 0 : Appearance.radius.normal
        bottomRightRadius: pos === "bottom" || pos === "right" ? 0 : Appearance.radius.normal
    }

    // ── Vertical ──
    Column {
        visible: vertical
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Appearance.spacing.small
        spacing: Appearance.spacing.normal

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ""
            color: Colours.primary
            font.family: Appearance.font.family
            font.pixelSize: Appearance.icon.size
        }
        Workspaces {}
    }

    Column {
        visible: vertical
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Appearance.spacing.small
        spacing: Appearance.spacing.normal

        Clock {}
        StatusIcons {}
        Tray {}
        PositionPicker {}
    }

    // ── Horizontal ──
    Row {
        visible: !vertical
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: Appearance.spacing.normal
        spacing: Appearance.spacing.normal

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: Colours.primary
            font.family: Appearance.font.family
            font.pixelSize: Appearance.icon.size
        }
        Workspaces {}
    }

    Clock {
        visible: !vertical
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
    }

    Row {
        visible: !vertical
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: Appearance.spacing.normal
        spacing: Appearance.spacing.normal

        StatusIcons {}
        Tray {}
        PositionPicker {}
    }
}
