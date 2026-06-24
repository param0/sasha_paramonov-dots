import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import "../../config"
import "../../services"

PanelWindow {
    id: osd

    property bool showing: false
    property bool ready: false
    property string mode: "volume"      // "volume" | "brightness"
    property real value: 0
    property bool muted: false

    anchors.bottom: true
    margins.bottom: 90
    implicitWidth: 340
    implicitHeight: 56
    exclusiveZone: -1   // center on the full screen, ignoring the bar's reserved zone
    color: "transparent"
    visible: showing

    // Suppress the OSD for initial property reads at startup.
    Timer { interval: 900; running: true; onTriggered: osd.ready = true }
    Timer { id: hideT; interval: 1500; onTriggered: osd.showing = false }

    function popup(m, v) {
        if (!osd.ready) return;
        osd.mode = m;
        osd.value = v;
        osd.showing = true;
        hideT.restart();
    }

    // ── Volume source ──
    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: osd.sink ? [osd.sink] : [] }

    Connections {
        target: osd.sink?.audio ?? null
        function onVolumeChanged() {
            osd.muted = osd.sink?.audio?.muted ?? false;
            osd.popup("volume", osd.sink?.audio?.volume ?? 0);
        }
        function onMutedChanged() {
            osd.muted = osd.sink?.audio?.muted ?? false;
            osd.popup("volume", osd.sink?.audio?.volume ?? 0);
        }
    }

    // ── Brightness source ──
    Connections {
        target: Brightness
        function onValueChanged() { osd.popup("brightness", Brightness.value); }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Appearance.radius.large
        color: Colours.surfaceContainer

        // entrance animation
        opacity: osd.showing ? 1 : 0
        scale: osd.showing ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: Appearance.anim.durationNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Appearance.anim.durationNormal; easing.type: Easing.OutBack } }

        Row {
            anchors.fill: parent
            anchors.leftMargin: Appearance.spacing.large
            anchors.rightMargin: Appearance.spacing.large
            spacing: Appearance.spacing.large

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: Appearance.icon.size
                height: Appearance.icon.size
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: osd.mode === "brightness" ? ""
                      : osd.muted ? ""
                      : osd.value > 0.5 ? "" : ""
                color: Colours.primary
                font.family: Appearance.font.family
                font.pixelSize: Appearance.icon.size
            }

            // progress track
            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - Appearance.icon.size - 56 - Appearance.spacing.large * 2
                height: 8
                radius: Appearance.radius.full
                color: Colours.surfaceVariant

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * Math.max(0, Math.min(1, osd.value))
                    color: osd.muted ? Colours.subtext : Colours.primary
                    Behavior on width { NumberAnimation { duration: Appearance.anim.durationFast; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                horizontalAlignment: Text.AlignRight
                text: Math.round(osd.value * 100) + "%"
                color: Colours.text
                font.family: Appearance.font.family
                font.pixelSize: Appearance.font.size
            }
        }
    }
}
