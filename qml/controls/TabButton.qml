import QtQuick
import "../theme"

Item {
    id: control

    property string text: "Tab"
    property bool isActive: false
    property int customWidth: 0
    signal clicked()

    implicitWidth: customWidth > 0 ? customWidth : (tabLabel.implicitWidth + 24)
    implicitHeight: 28
    width: implicitWidth
    height: parent ? parent.height : 28

    Theme { id: theme }

    // Drop shadow beneath active tab to give the "timbul" physical elevation
    Rectangle {
        anchors.fill: tabBody
        anchors.topMargin: 1
        anchors.bottomMargin: -1
        radius: theme.radiusButton
        color: theme.btnPrimaryShadow
        opacity: control.isActive ? 0.85 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: 150 }
        }
    }

    // Physical Body
    Rectangle {
        id: tabBody
        anchors.fill: parent
        radius: theme.radiusButton

        color: control.isActive ? "transparent" : (mouseArea.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent")

        gradient: control.isActive ? activeGradient : null

        Gradient {
            id: activeGradient
            GradientStop {
                position: 0.0
                color: mouseArea.pressed ? theme.btnPrimaryPressed : (mouseArea.containsMouse ? theme.btnPrimaryHoverTop : theme.btnPrimaryTop)
            }
            GradientStop {
                position: 1.0
                color: mouseArea.pressed ? theme.btnPrimaryPressed : (mouseArea.containsMouse ? theme.btnPrimaryHoverBottom : theme.btnPrimaryBottom)
            }
        }

        border.color: control.isActive ? theme.btnPrimaryBorderSides : "transparent"
        border.width: control.isActive ? 1 : 0

        // Top highlight bevel (authentic tactile edge)
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 1
            color: "#FFFFFF"
            opacity: control.isActive ? 0.22 : 0.0
            radius: 5
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }

        Text {
            id: tabLabel
            anchors.centerIn: parent
            text: control.text
            color: control.isActive ?
                   theme.textPrimary :
                   (mouseArea.containsMouse ? theme.textPrimary : theme.textSecondary)
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
            font.weight: control.isActive ? Font.DemiBold : Font.Medium
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
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

