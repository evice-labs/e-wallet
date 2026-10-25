import QtQuick
import "../theme"

Rectangle {
    id: control

    property string text: "Badge"
    property color badgeColor: "#0A70F5"

    implicitWidth: badgeText.implicitWidth + 18
    implicitHeight: 22
    radius: 11

    color: Qt.rgba(control.badgeColor.r, control.badgeColor.g, control.badgeColor.b, 0.14)
    border.color: Qt.rgba(control.badgeColor.r, control.badgeColor.g, control.badgeColor.b, 0.40)
    border.width: 1

    Theme { id: theme }

    Text {
        id: badgeText
        anchors.centerIn: parent
        text: control.text
        color: control.badgeColor
        font.family: theme.fontMono
        font.pixelSize: theme.fontSizeTiny
        font.weight: Font.DemiBold
        font.capitalization: Font.AllUppercase
    }
}
