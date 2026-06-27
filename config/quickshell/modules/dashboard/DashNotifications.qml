import Quickshell
import QtQuick
import "../../config"
import "../../services"

Column {
    id: root
    spacing: Appearance.spacing.normal

    // Header
    Row {
        width: parent.width
        spacing: Appearance.spacing.small

        Text {
            text: ""
            color: Colours.primary
            font.family: Appearance.font.family
            font.pixelSize: Appearance.icon.size
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: I18n.s.notifications ?? "Notifications"
            color: Colours.text
            font.family: Appearance.font.family
            font.pixelSize: Appearance.font.size
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: Notifications.count > 0
            text: "(" + Notifications.count + ")"
            color: Colours.subtext
            font.family: Appearance.font.family
            font.pixelSize: Appearance.font.sizeSmall
            anchors.verticalCenter: parent.verticalCenter
        }

        Item { width: parent.width - clearBtn.width - dismissAll.width - 120; height: 1 }

        // Restore last dismissed
        Rectangle {
            id: clearBtn
            width: 28; height: 28
            radius: Appearance.radius.small
            color: clearHover.hovered ? Colours.surfaceVariant : "transparent"
            HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Notifications.restore() }

            Text {
                anchors.centerIn: parent
                text: ""
                color: Colours.subtext
                font.family: Appearance.font.family
                font.pixelSize: Appearance.icon.size
            }
        }

        // Dismiss all
        Rectangle {
            id: dismissAll
            width: 28; height: 28
            radius: Appearance.radius.small
            color: dismissHover.hovered ? Colours.surfaceVariant : "transparent"
            visible: Notifications.count > 0
            HoverHandler { id: dismissHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Notifications.dismissAll() }

            Text {
                anchors.centerIn: parent
                text: "󰎟"
                color: Colours.error
                font.family: Appearance.font.family
                font.pixelSize: Appearance.icon.size
            }
        }
    }

    // Separator
    Rectangle {
        width: parent.width
        height: 1
        color: Colours.outline
        opacity: 0.3
    }

    // Notification list
    ListView {
        width: parent.width
        height: Math.min(contentHeight, 220)
        clip: true
        spacing: Appearance.spacing.small

        model: Notifications.notifications

        delegate: Rectangle {
            id: notifCard
            required property var modelData
            width: parent?.width ?? 0
            height: contentCol.implicitHeight + Appearance.spacing.normal * 2
            radius: Appearance.radius.normal
            color: notifHover.hovered ? Colours.surfaceVariant : Colours.surfaceContainer

            Behavior on color { ColorAnimation { duration: Appearance.anim.durationFast } }

            HoverHandler { id: notifHover }

            Column {
                id: contentCol
                anchors.fill: parent
                anchors.margins: Appearance.spacing.normal
                spacing: 4

                Row {
                    width: parent.width
                    spacing: Appearance.spacing.small

                    Text {
                        id: appLabel
                        text: modelData.app || ""
                        color: Colours.primary
                        font.family: Appearance.font.family
                        font.pixelSize: Appearance.font.sizeSmall
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Item { width: parent.width - appLabel.width - closeBtn.width - 20; height: 1 }

                    Rectangle {
                        id: closeBtn
                        width: 20; height: 20
                        radius: Appearance.radius.full
                        color: closeHover.hovered ? Colours.error : "transparent"
                        HoverHandler { id: closeHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: Notifications.dismiss(modelData.id) }

                        Text {
                            anchors.centerIn: parent
                            text: ""
                            color: closeHover.hovered ? Colours.primaryText : Colours.subtext
                            font.pixelSize: 10
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: modelData.summary || ""
                    color: Colours.text
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.size
                    wrapMode: Text.WordWrap
                }

                Text {
                    width: parent.width
                    visible: modelData.body && modelData.body.length > 0
                    text: modelData.body || ""
                    color: Colours.subtext
                    font.family: Appearance.font.family
                    font.pixelSize: Appearance.font.sizeSmall
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }
        }

        // Empty state
        Text {
            anchors.centerIn: parent
            visible: Notifications.count === 0
            text: "󰂚 " + I18n.s.noNotifications
            color: Colours.outline
            font.family: Appearance.font.family
            font.pixelSize: Appearance.font.size
        }
    }
}
