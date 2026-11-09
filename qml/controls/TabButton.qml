import QtQuick
import "../theme"

Item {
    id: control

    property string text: "Tab"
    property bool isActive: false
    property bool isDestructive: false
    property bool isMuted: false
    property color inactiveTextColor: "transparent"
    property int cursorShape: Qt.PointingHandCursor
    property int customWidth: 0
    signal clicked

    implicitWidth: customWidth > 0 ? customWidth : (tabLabel.implicitWidth + 24)
    implicitHeight: 28
    width: implicitWidth
    height: parent ? parent.height : 28

    Theme {
        id: theme
    }

    // Drop shadow beneath active tab to give the physical elevation
    Rectangle {
        anchors.fill: tabBody
        anchors.topMargin: 1
        anchors.bottomMargin: -1
        radius: theme.radiusButton
        color: control.isDestructive ? Qt.rgba(0.9, 0.1, 0.1, 0.28) : theme.btnPrimaryShadow
        opacity: control.isActive ? 0.85 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
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
                color: {
                    if (control.isMuted) {
                        return Qt.rgba(0.25, 0.25, 0.28, 0.6);
                    }
                    if (control.isDestructive) {
                        return mouseArea.pressed ? "#991B1B" : (mouseArea.containsMouse ? "#DC2626" : "#B91C1C");
                    }
                    return mouseArea.pressed ? theme.btnPrimaryPressed : (mouseArea.containsMouse ? theme.btnPrimaryHoverTop : theme.btnPrimaryTop);
                }
            }
            GradientStop {
                position: 1.0
                color: {
                    if (control.isMuted) {
                        return Qt.rgba(0.18, 0.18, 0.2, 0.6);
                    }
                    if (control.isDestructive) {
                        return mouseArea.pressed ? "#7F1D1D" : (mouseArea.containsMouse ? "#B91C1C" : "#991B1B");
                    }
                    return mouseArea.pressed ? theme.btnPrimaryPressed : (mouseArea.containsMouse ? theme.btnPrimaryHoverBottom : theme.btnPrimaryBottom);
                }
            }
        }

        border.color: control.isActive ? (control.isMuted ? theme.borderSubtle : (control.isDestructive ? "#EF4444" : theme.btnPrimaryBorderSides)) : "transparent"
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
                NumberAnimation {
                    duration: 150
                }
            }
        }

        Text {
            id: tabLabel
            anchors.centerIn: parent
            text: control.text
            color: control.isActive ? (control.isMuted && control.inactiveTextColor.a > 0 ? control.inactiveTextColor : theme.textPrimary) : (mouseArea.containsMouse ? (control.inactiveTextColor.a > 0 ? control.inactiveTextColor : theme.textPrimary) : (control.inactiveTextColor.a > 0 ? control.inactiveTextColor : theme.textSecondary))
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
        cursorShape: control.cursorShape
        onClicked: control.clicked()
    }
}
