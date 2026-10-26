import QtQuick
import "../theme"

Rectangle {
    id: control

    property alias text: input.text
    property string placeholder: "Enter text..."
    property string label: ""
    property int echoMode: TextInput.Normal
    property bool readOnly: false
    property alias validator: input.validator
    signal accepted()

    implicitWidth: 320
    implicitHeight: control.label.length > 0 ? 66 : 42
    radius: theme.radiusButton

    color: theme.bgInsetTrough
    border.color: input.activeFocus ? theme.borderActive : theme.borderSubtle
    border.width: input.activeFocus ? 1.5 : 1

    Theme { id: theme }

    Column {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 4

        Text {
            text: control.label
            color: theme.textSecondary
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
            visible: control.label.length > 0
        }

        TextInput {
            id: input
            width: parent.width
            height: 24
            color: theme.textPrimary
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeBody
            echoMode: control.echoMode
            readOnly: control.readOnly
            clip: true
            verticalAlignment: TextInput.AlignVCenter
            onAccepted: control.accepted()

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: control.placeholder
                color: theme.textMuted
                font: input.font
                visible: !input.text && !input.activeFocus
            }
        }
    }
}
