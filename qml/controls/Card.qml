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

    Theme {
        id: theme
    }

    radius: theme.radiusCard
    color: theme.bgSurface
    border.color: "transparent"
    border.width: 0

    ColumnLayout {
        id: cardMainLayout
        anchors.fill: parent
        anchors.margins: theme.spacingLarge
        spacing: theme.spacingMedium

        // Card Header
        Item {
            id: headerContainer
            Layout.fillWidth: true
            implicitHeight: Math.max(38, Math.max(headerCol.implicitHeight, headerRightLoader.implicitHeight))
            visible: control.title.length > 0 || (headerRightLoader.item !== null)

            Column {
                id: headerCol
                anchors.left: parent.left
                anchors.right: (headerRightLoader.item !== null) ? headerRightLoader.left : parent.right
                anchors.rightMargin: (headerRightLoader.item !== null) ? theme.spacingMedium : 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: theme.spacingTiny

                // 3. Card Title
                Text {
                    width: parent.width
                    text: control.title
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.panelTitleText
                    font.weight: Font.Bold
                }

                // 3. Subtitle / Description Card
                Text {
                    width: parent.width
                    text: control.subtitle
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.secondaryText
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
