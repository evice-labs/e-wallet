import QtQuick
import QtQuick.Layouts
import "../theme"

Rectangle {
    id: control

    property string title: ""
    property string subtitle: ""
    property Component headerRight: null
    default property alias content: contentSlot.data

    implicitWidth: 400
    implicitHeight: Math.max(80, cardMainLayout.implicitHeight + 32)
    Layout.fillWidth: true
    radius: 0

    Theme { id: theme }

    color: theme.bgSurface
    border.color: theme.borderSubtle
    border.width: 1

    ColumnLayout {
        id: cardMainLayout
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        // Card Header
        Item {
            id: headerContainer
            Layout.fillWidth: true
            implicitHeight: Math.max(headerCol.implicitHeight, headerRightLoader.implicitHeight)
            visible: control.title.length > 0 || (headerRightLoader.item !== null)

            Column {
                id: headerCol
                anchors.left: parent.left
                anchors.right: (headerRightLoader.item !== null) ? headerRightLoader.left : parent.right
                anchors.rightMargin: (headerRightLoader.item !== null) ? 12 : 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    width: parent.width
                    text: control.title
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTitle
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: control.subtitle
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                    visible: control.subtitle.length > 0
                    wrapMode: Text.WordWrap
                }
            }

            Loader {
                id: headerRightLoader
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                sourceComponent: control.headerRight
            }
        }

        // Child Content Slot (Fills available vertical space)
        Item {
            id: contentSlot
            Layout.fillWidth: true
            Layout.fillHeight: true
            implicitHeight: childrenRect.height
            clip: true
        }
    }
}

