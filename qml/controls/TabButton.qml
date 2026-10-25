import QtQuick
import "../theme"

Item {
    id: control

    property string text: "Tab"
    property bool isActive: false
    signal clicked()

    implicitWidth: tabLabel.implicitWidth + 24
    implicitHeight: 32

    Theme { id: theme }

    Rectangle {
        id: tabBody
        anchors.fill: parent
        radius: theme.radiusButton
        color: control.isActive ? theme.bgSurfaceElevated : (mouseArea.containsMouse ? theme.bgSurfaceSubtle : "transparent")
        border.color: control.isActive ? theme.borderCard : "transparent"
        border.width: 1

        // Top Specular Highlight if active
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 4
            height: 1
            color: theme.bevelHighlightSubtle
            visible: control.isActive
        }

        Text {
            id: tabLabel
            anchors.centerIn: parent
            text: control.text
            color: control.isActive ? theme.textPrimary : (mouseArea.containsMouse ? theme.textSecondary : theme.textMuted)
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeBody
            font.weight: control.isActive ? Font.DemiBold : Font.Normal
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: control.clicked()
    }
}
