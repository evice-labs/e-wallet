import QtQuick
import "../theme"

Rectangle {
    id: control

    default property alias content: tabRow.data
    property alias spacing: tabRow.spacing

    implicitHeight: 34
    implicitWidth: tabRow.implicitWidth + 6

    color: theme.bgInsetTrough
    radius: 8
    border.color: theme.borderSubtle
    border.width: 1

    Theme { id: theme }

    Row {
        id: tabRow
        x: 3
        y: 3
        height: control.height > 6 ? (control.height - 6) : 28
        spacing: 3
    }
}
