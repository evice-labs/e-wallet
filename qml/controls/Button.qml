import QtQuick
import "../theme"

Item {
    id: control

    property string text: "Button"
    property bool isPrimary: false
    property bool isCompact: false
    property bool isDestructive: false
    signal clicked()

    implicitWidth: Math.max(isCompact ? 72 : 110, labelText.implicitWidth + (isCompact ? 20 : 32))
    implicitHeight: isCompact ? 30 : 38

    opacity: control.enabled ? 1.0 : 0.45

    Theme { id: theme }

    // Outer drop shadow (gives physical elevation)
    Rectangle {
        anchors.fill: buttonBody
        anchors.topMargin: 2
        anchors.bottomMargin: -2
        radius: isCompact ? 7 : theme.radiusButton
        color: control.isPrimary ? theme.btnPrimaryShadow : theme.btnSecondaryShadow
        opacity: mouseArea.pressed ? 0.2 : 0.8
    }

    // Button Physical Body
    Rectangle {
        id: buttonBody
        anchors.fill: parent
        anchors.topMargin: mouseArea.pressed ? 1 : 0
        anchors.bottomMargin: mouseArea.pressed ? -1 : 0
        radius: isCompact ? 7 : theme.radiusButton

        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: {
                    if (control.isDestructive) return mouseArea.pressed ? "#991B1B" : (mouseArea.containsMouse ? "#DC2626" : "#B91C1C")
                    if (control.isPrimary) return mouseArea.pressed ? theme.btnPrimaryPressed : (mouseArea.containsMouse ? theme.btnPrimaryHoverTop : theme.btnPrimaryTop)
                    return mouseArea.pressed ? theme.btnSecondaryPressed : (mouseArea.containsMouse ? theme.btnSecondaryHoverTop : theme.btnSecondaryTop)
                }
            }
            GradientStop {
                position: 1.0
                color: {
                    if (control.isDestructive) return mouseArea.pressed ? "#7F1D1D" : (mouseArea.containsMouse ? "#B91C1C" : "#991B1B")
                    if (control.isPrimary) return mouseArea.pressed ? theme.btnPrimaryPressed : (mouseArea.containsMouse ? theme.btnPrimaryHoverBottom : theme.btnPrimaryBottom)
                    return mouseArea.pressed ? theme.btnSecondaryPressed : (mouseArea.containsMouse ? theme.btnSecondaryHoverBottom : theme.btnSecondaryBottom)
                }
            }
        }

        border.color: control.isPrimary ? theme.btnPrimaryBorderSides : theme.btnSecondaryBorderSides
        border.width: 1

        // Top Specular Highlight (The signature skeuomorphic bevel edge)
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 4
            height: 1
            color: control.isPrimary ? theme.btnPrimaryBorderTop : theme.btnSecondaryBorderTop
            opacity: mouseArea.pressed ? 0.2 : 1.0
        }

        // Pure Typographic Text (Strict Zero-Icon Rule)
        Text {
            id: labelText
            anchors.centerIn: parent
            text: control.text
            color: theme.textPrimary
            font.family: theme.fontFamily
            font.pixelSize: control.isCompact ? theme.fontSizeSmall : theme.fontSizeBody
            font.weight: control.isPrimary ? Font.DemiBold : Font.Medium
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: control.enabled
        cursorShape: control.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (control.enabled) control.clicked()
        }
    }
}
