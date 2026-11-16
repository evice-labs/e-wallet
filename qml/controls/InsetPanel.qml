import QtQuick
import "../theme"

Rectangle {
    id: control

    default property alias content: contentSlot.data

    implicitWidth: 320
    implicitHeight: 80
    radius: theme.radiusInset

    color: theme.bgInsetTrough
    border.color: "transparent"
    border.width: 0
    clip: true

    Theme {
        id: theme
    }

    Item {
        id: contentSlot
        anchors.fill: parent
        anchors.margins: 12
    }
}
