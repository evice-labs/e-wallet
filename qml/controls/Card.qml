import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: control

    property string title: ""
    property string subtitle: ""
    default property alias content: contentSlot.data

    implicitWidth: 400
    implicitHeight: Math.max(80, cardMainColumn.implicitHeight + 40)
    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight
    Layout.minimumHeight: implicitHeight
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

    Column {
        id: cardMainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 16

        // Card Header
        Column {
            id: headerCol
            width: parent.width
            visible: control.title.length > 0
            spacing: 4

            Text {
                width: parent.width
                text: control.title
                color: theme.textPrimary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTitle
                font.weight: Font.DemiBold
            }

            Text {
                width: parent.width
                text: control.subtitle
                color: theme.textSecondary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeSmall
                visible: control.subtitle.length > 0
                wrapMode: Text.WordWrap
            }
        }

        // Child Content Slot
        Item {
            id: contentSlot
            width: parent.width
            implicitHeight: childrenRect.height
            height: implicitHeight
        }
    }
}

