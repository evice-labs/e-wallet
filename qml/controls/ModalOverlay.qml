import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: overlay

    anchors.fill: parent
    visible: opacity > 0
    opacity: 0
    z: 200

    property string title: "Modal Title"
    property string subtitle: ""
    property int dialogWidth: 480
    property int dialogHeight: 400
    property bool dismissible: true

    signal closed()

    default property alias content: contentContainer.data

    Theme { id: theme }

    Behavior on opacity {
        NumberAnimation { duration: 180; easing.type: Easing.OutQuad }
    }

    function open() {
        overlay.opacity = 1.0;
    }

    function close() {
        overlay.opacity = 0.0;
        overlay.closed();
    }

    // Backdrop with Gaussian blur / dim effect
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: Qt.rgba(0.02, 0.02, 0.03, 0.85)

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (overlay.dismissible) {
                    overlay.close();
                }
            }
        }
    }

    // Tactile Modal Card Dialog
    Rectangle {
        id: dialogCard
        width: Math.min(parent.width - 40, overlay.dialogWidth)
        height: Math.min(parent.height - 40, overlay.dialogHeight)
        anchors.centerIn: parent
        radius: theme.radiusCard
        color: theme.bgSurfaceElevated
        border.color: theme.borderCard
        border.width: 1

        // Eat clicks inside modal dialog
        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // Modal Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Column {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: overlay.title
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTitle
                        font.weight: Font.Bold
                    }

                    Text {
                        visible: overlay.subtitle.length > 0
                        text: overlay.subtitle
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                }

                Button {
                    visible: overlay.dismissible
                    text: "Close"
                    isCompact: true
                    isPrimary: false
                    onClicked: overlay.close()
                }
            }

            // Divider Line
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: theme.borderSubtle
            }

            // Content Bay
            Item {
                id: contentContainer
                Layout.fillWidth: true
                Layout.fillHeight: true
            }
        }
    }
}
