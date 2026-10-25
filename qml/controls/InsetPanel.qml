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

    // Upper Inner Shadow for Sunken Tactile Effect
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 4
        radius: theme.radiusInset
        color: theme.innerShadowDark
    }

    Item {
        id: contentSlot
        anchors.fill: parent
        anchors.margins: 12
    }
}
