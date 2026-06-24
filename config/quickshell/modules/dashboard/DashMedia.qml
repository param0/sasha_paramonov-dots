import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import "../../config"
import "../../services"

Rectangle {
    id: root
    radius: Appearance.radius.normal
    color: Colours.surfaceContainer

    readonly property var player: {
        const ps = Mpris.players?.values ?? [];
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null;
    }

    property real pos: 0
    property real len: 0

    function fmt(sec) {
        if (!sec || sec < 0) return "0:00";
        const s = Math.floor(sec);
        return Math.floor(s / 60) + ":" + ("0" + (s % 60)).slice(-2);
    }

    Timer {
        interval: 1000
        running: root.player !== null
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.pos = root.player?.position ?? 0;
            root.len = root.player?.length ?? 0;
        }
    }

    // Scroll over the player to seek +/-5s.
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const p = root.player;
            if (!p) return;
            const np = Math.max(0, Math.min(p.length || 0, (p.position || 0) + (event.angleDelta.y > 0 ? 5 : -5)));
            p.position = np;
            root.pos = np;
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !root.player
        text: "  " + I18n.s.nothingPlaying
        color: Colours.subtext
        font.family: Appearance.font.family
        font.pixelSize: Appearance.font.size
    }

    Row {
        anchors.fill: parent
        anchors.margins: Appearance.spacing.large
        spacing: Appearance.spacing.large
        visible: root.player !== null

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 84; height: 84
            radius: Appearance.radius.small
            color: Colours.surfaceVariant
            clip: true
            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: !root.player?.trackArtUrl
                text: ""
                color: Colours.subtext
                font.family: Appearance.font.family
                font.pixelSize: 30
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 84 - Appearance.spacing.large
            spacing: Appearance.spacing.small

            Text {
                width: parent.width
                text: root.player?.trackTitle ?? ""
                color: Colours.text
                font.family: Appearance.font.family
                font.pixelSize: Appearance.font.size
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.player?.trackArtist ?? ""
                color: Colours.subtext
                font.family: Appearance.font.family
                font.pixelSize: Appearance.font.sizeSmall
                elide: Text.ElideRight
            }

            // controls
            Row {
                spacing: Appearance.spacing.large
                topPadding: 2

                Repeater {
                    model: [
                        { "icon": "", "act": "previous" },
                        { "icon": "play",   "act": "toggle" },
                        { "icon": "",  "act": "next" }
                    ]
                    delegate: Text {
                        required property var modelData
                        height: Appearance.icon.size + 4
                        verticalAlignment: Text.AlignVCenter
                        text: modelData.act === "toggle"
                              ? (root.player?.isPlaying ? "" : "")
                              : modelData.icon
                        color: ma2.containsMouse ? Colours.primary : Colours.text
                        font.family: Appearance.font.family
                        font.pixelSize: modelData.act === "toggle" ? Appearance.icon.size + 4 : Appearance.icon.size
                        MouseArea {
                            id: ma2
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (!root.player) return;
                                if (modelData.act === "toggle") root.player.togglePlaying();
                                else if (modelData.act === "next") root.player.next();
                                else root.player.previous();
                            }
                        }
                    }
                }
            }

            // progress bar
            Rectangle {
                id: track
                width: parent.width
                height: 5
                radius: Appearance.radius.full
                color: Colours.surfaceVariant

                Rectangle {
                    height: parent.height
                    radius: parent.radius
                    width: parent.width * (root.len > 0 ? Math.max(0, Math.min(1, root.pos / root.len)) : 0)
                    color: Colours.primary
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        const p = root.player;
                        if (!p || !root.len) return;
                        const np = Math.max(0, Math.min(root.len, (mouse.x / track.width) * root.len));
                        p.position = np;
                        root.pos = np;
                    }
                }
            }

            // elapsed / total
            Item {
                width: parent.width
                height: childrenRect.height

                Text {
                    anchors.left: parent.left
                    text: root.fmt(root.pos)
                    color: Colours.subtext
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.sizeSmall
                }
                Text {
                    anchors.right: parent.right
                    text: root.fmt(root.len)
                    color: Colours.subtext
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.sizeSmall
                }
            }
        }
    }
}
