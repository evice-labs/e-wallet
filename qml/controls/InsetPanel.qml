import QtQuick
import "../theme"

Rectangle {
    id: control

    default property alias content: contentSlot.data

    implicitWidth: 320
    implicitHeight: 80
    radius: theme.radiusInset

    color: theme.bgInsetTrough
    border.color: theme.borderSubtle
    border.width: 1

    Theme { id: theme }

    // Skeuomorphic Sunken Inner Top Shadow
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: control.radius
        anchors.rightMargin: control.radius
        height: 1
        color: Qt.rgba(0.0, 0.0, 0.0, 0.40)
    }

    Item {
        id: contentSlot
        anchors.fill: parent
        anchors.margins: 12
    }
}
