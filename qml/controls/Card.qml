import QtQuick
import "../theme"

Rectangle {
    id: control

    property string title: ""
    property string subtitle: ""
    default property alias content: contentSlot.data

    implicitWidth: 400
    implicitHeight: 250
    radius: theme.radiusCard

    color: theme.bgSurface
    border.color: theme.borderCard
    border.width: 1

    Theme { id: theme }

    // Drop Shadow for Card Elevation
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: -4
        radius: control.radius
        color: theme.shadowDropDark
        z: -1
    }

    // Top Specular Highlight Bevel
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 4
        height: 1
        color: theme.bevelHighlightSubtle
    }

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Card Header (Pure Typography, Zero Icon)
        Row {
            width: parent.width
            visible: control.title.length > 0

            Column {
                width: parent.width
                spacing: 4

                Text {
                    text: control.title
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTitle
                    font.weight: Font.DemiBold
                }

                Text {
                    text: control.subtitle
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                    visible: control.subtitle.length > 0
                }
            }
        }

        // Child Content Slot
        Item {
            id: contentSlot
            width: parent.width
            height: parent.height - (control.title.length > 0 ? 50 : 0)
        }
    }
}
