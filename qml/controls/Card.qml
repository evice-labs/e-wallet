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
    implicitHeight: Math.max(80, cardMainColumn.implicitHeight + 40)
    Layout.fillWidth: true
    Layout.preferredHeight: implicitHeight
    Layout.minimumHeight: implicitHeight
    radius: theme.radiusCard

    Theme { id: theme }

    // Skeuomorphic Surface Gradient (Subtle 3D depth centered on theme.bgSurface #262626)
    gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.lighter(theme.bgSurface, 1.05) }
        GradientStop { position: 0.5; color: theme.bgSurface }
        GradientStop { position: 1.0; color: Qt.darker(theme.bgSurface, 1.04) }
    }

    border.color: theme.borderCard
    border.width: 1

    // Skeuomorphic Ambient Drop Shadow (Layer 1 - Soft Spread)
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        anchors.topMargin: 2
        anchors.bottomMargin: -2
        radius: control.radius + 1
        color: theme.shadowDropDark
        opacity: 0.35
        z: -2
    }

    // Skeuomorphic Directional Drop Shadow (Layer 2 - Deep Downward Drop)
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 5
        anchors.bottomMargin: -5
        radius: control.radius
        color: Qt.rgba(0.0, 0.0, 0.0, 0.45)
        z: -1
    }

    // Skeuomorphic Top Specular Chiseled Highlight (1px Rim Light)
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 1
        anchors.leftMargin: control.radius
        anchors.rightMargin: control.radius
        height: 1
        color: theme.bevelHighlightTop
        z: 2
    }

    Column {
        id: cardMainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20
        spacing: 16

        // Card Header
        Item {
            id: headerContainer
            width: parent.width
            implicitHeight: Math.max(headerCol.implicitHeight, headerRightLoader.implicitHeight)
            height: implicitHeight
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

        // Child Content Slot
        Item {
            id: contentSlot
            width: parent.width
            implicitHeight: childrenRect.height
            height: implicitHeight
        }
    }
}

