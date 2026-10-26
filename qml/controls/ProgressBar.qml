import QtQuick
import "../theme"

Item {
    id: control

    property real value: 0.0        // Current progress (0.0 to 1.0)
    property string title: ""       // Left label
    property string readout: ""     // Right label (e.g. "1 / 3,000")
    property color barColor: "#FF8438" // Default vibrant orange from reference

    implicitWidth: 320
    implicitHeight: title.length > 0 ? 50 : 12

    Theme { id: theme }

    Column {
        anchors.fill: parent
        spacing: 8

        // Header Readout Row
        Row {
            width: parent.width
            visible: control.title.length > 0 || control.readout.length > 0

            Text {
                width: parent.width - readoutText.implicitWidth
                text: control.title
                color: theme.textSecondary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeBody
                elide: Text.ElideRight
            }

            Text {
                id: readoutText
                text: control.readout
                color: theme.textPrimary
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeBody
                font.weight: Font.Medium
            }
        }

        // Tactile Inset Groove / Trough
        Rectangle {
            width: parent.width
            height: 8
            radius: theme.radiusProgress
            color: theme.bgInsetTrough
            border.color: theme.borderSubtle
            border.width: 1

            // Illuminated Progress Fill
            Rectangle {
                id: progressFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 1
                width: Math.max(0, Math.min(parent.width - 2, (parent.width - 2) * Math.max(0.0, Math.min(1.0, control.value))))
                radius: theme.radiusProgress

                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(control.barColor, 1.15) }
                    GradientStop { position: 1.0; color: control.barColor }
                }

                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
            }
        }
    }
}
