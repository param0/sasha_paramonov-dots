import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import QtQuick
import "../../config"
import "../../services"

Column {
    id: root
    spacing: Appearance.spacing.large

    property bool wifiOn: true
    property bool dndOn: false

    PwObjectTracker { objects: Pipewire.defaultAudioSink ? [Pipewire.defaultAudioSink] : [] }

    // Toggles
    Row {
        spacing: Appearance.spacing.normal

        Repeater {
            model: [
                { "icon": "", "key": "wifi" },
                { "icon": "",   "key": "bt" },
                { "icon": "",  "key": "dnd" }
            ]
            delegate: Rectangle {
                required property var modelData
                width: 64; height: 48
                radius: Appearance.radius.normal

                readonly property bool active: modelData.key === "bt"
                    ? (Bluetooth.defaultAdapter?.enabled ?? false)
                    : modelData.key === "wifi" ? root.wifiOn : root.dndOn

                color: active ? Colours.primary : Colours.surfaceContainer
                Behavior on color { ColorAnimation { duration: Appearance.anim.durationFast } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    color: parent.active ? Colours.primaryText : Colours.text
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.icon.size
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.key === "bt") {
                            if (Bluetooth.defaultAdapter) Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled;
                        } else if (modelData.key === "wifi") {
                            root.wifiOn = !root.wifiOn;
                            Quickshell.execDetached(["sh", "-c", "nmcli radio wifi " + (root.wifiOn ? "on" : "off")]);
                        } else {
                            root.dndOn = !root.dndOn;
                            Quickshell.execDetached(["sh", "-c", "makoctl mode -t do-not-disturb"]);
                        }
                    }
                }
            }
        }
    }

    DashSlider {
        width: parent.width
        icon: ""
        value: Brightness.value
        onMoved: v => Brightness.setValue(v)
    }
    DashSlider {
        width: parent.width
        icon: ""
        value: Pipewire.defaultAudioSink?.audio?.volume ?? 0
        onMoved: v => { const a = Pipewire.defaultAudioSink?.audio; if (a) a.volume = v; }
    }
}
