import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Item {
    id: view

    required property var bridge
    required property var accountStore

    signal openCreateAccount()
    signal openAccountDetail(var account)
    signal navigateTab(string tabName)

    Theme { id: theme }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentLayout.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // Sleek Minimalist Scroll Indicator
        Rectangle {
            id: scrollIndicator
            anchors.right: parent.right
            anchors.rightMargin: 2
            y: flickable.visibleArea.yPosition * flickable.height
            width: 4
            height: Math.max(30, flickable.visibleArea.heightRatio * flickable.height)
            radius: 2
            color: theme.borderActive
            opacity: flickable.moving || flickable.dragging ? 0.7 : 0.3
            visible: flickable.visibleArea.heightRatio < 1.0
            z: 10
        }

        ColumnLayout {
            id: contentLayout
            width: parent.width - (scrollIndicator.visible ? 10 : 0)
            spacing: 16

            // Usage & Action Hero Section
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Vault Overview"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeHero
                        font.weight: Font.Bold
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Create Account"
                        isPrimary: true
                        enabled: !bridge.isLocked
                        onClicked: view.openCreateAccount()
                    }

                    Button {
                        text: "Transfer Assets"
                        isPrimary: false
                        enabled: !bridge.isLocked && accountStore.accounts.length > 0
                        onClicked: view.navigateTab("transfer")
                    }
                }

                // Recessed Grooved Progress Bar
                ProgressBar {
                    Layout.fillWidth: true
                    title: "Logos testnet 0.4 epoch quota used"
                    readout: "1 / 3,000"
                    value: 1.0 / 3000.0
                    barColor: theme.accentOrange
                }
            }

            // Active Account Hero Card
            Card {
                Layout.fillWidth: true
                title: "Hardware Keystore Portfolio"

                ColumnLayout {
                    width: parent.width
                    height: implicitHeight
                    spacing: 14

                    // Two-Column Portfolio Balance Display
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        InsetPanel {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "PUBLIC TRANSPARENT HOLDINGS"
                                    color: theme.textSecondary
                                    font.family: theme.fontMono
                                    font.pixelSize: theme.fontSizeSmall
                                    font.weight: Font.Medium
                                }

                                Text {
                                    text: accountStore.totalPublicBalance + " LEZ"
                                    color: theme.textPrimary
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontSizeTitle + 2
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        InsetPanel {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "SHIELDED ZERO-KNOWLEDGE HOLDINGS"
                                    color: theme.statusShielded
                                    font.family: theme.fontMono
                                    font.pixelSize: theme.fontSizeSmall
                                    font.weight: Font.Medium
                                }

                                Text {
                                    text: accountStore.totalShieldedBalance + " LEZ"
                                    color: theme.textPrimary
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontSizeTitle + 2
                                    font.weight: Font.Bold
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        PillBadge {
                            text: "Accounts Managed: " + accountStore.accounts.length
                            badgeColor: theme.statusPublic
                        }

                        PillBadge {
                            text: "Program Registry LP-0023 Verified"
                            badgeColor: theme.statusSuccess
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: "Refresh Balances"
                            isPrimary: false
                            isCompact: true
                            enabled: !bridge.isLocked
                            onClicked: accountStore.refreshAccounts()
                        }
                    }
                }
            }

            // Accounts List Workspace (Adaptive Height for responsive vertical scrolling)
            Card {
                Layout.fillWidth: true
                title: "Accounts & Privacy Keys"
                subtitle: "Click an account to select as active sender"

                ColumnLayout {
                    width: parent.width
                    height: implicitHeight
                    spacing: 8

                    Repeater {
                        model: accountStore.accounts
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 62
                            height: 62
                            radius: theme.radiusButton
                            color: (accountStore.activeAccount && accountStore.activeAccount.account_id === modelData.account_id)
                                   ? theme.bgSurfaceElevated : (accountMouse.containsMouse ? theme.bgSurfaceSubtle : theme.bgSurface)
                            border.color: (accountStore.activeAccount && accountStore.activeAccount.account_id === modelData.account_id)
                                          ? theme.borderActive : theme.borderSubtle
                            border.width: 1

                            MouseArea {
                                id: accountMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: accountStore.selectAccount(modelData)
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 14

                                Column {
                                    spacing: 4
                                    Row {
                                        spacing: 8
                                        Text {
                                            text: modelData.label || "Unnamed Account"
                                            color: theme.textPrimary
                                            font.family: theme.fontFamily
                                            font.pixelSize: theme.fontSizeBody
                                            font.weight: Font.Bold
                                        }

                                        PillBadge {
                                            text: modelData.is_private ? "SHIELDED" : "PUBLIC"
                                            badgeColor: modelData.is_private ? theme.statusShielded : theme.statusPublic
                                        }

                                        Text {
                                            visible: accountStore.activeAccount && accountStore.activeAccount.account_id === modelData.account_id
                                            text: "• ACTIVE"
                                            color: theme.accentBlue
                                            font.family: theme.fontMono
                                            font.pixelSize: theme.fontSizeSmall
                                            font.weight: Font.Bold
                                        }
                                    }

                                    Text {
                                        text: modelData.account_id.substring(0, 32) + "..."
                                        color: theme.textMuted
                                        font.family: theme.fontMono
                                        font.pixelSize: theme.fontSizeSmall
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: (modelData.formatted_balance || "0.00") + " LEZ"
                                    color: theme.textPrimary
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontSizeTitle
                                    font.weight: Font.Bold
                                }

                                Button {
                                    text: "Details"
                                    isPrimary: false
                                    isCompact: true
                                    onClicked: view.openAccountDetail(modelData)
                                }
                            }
                        }
                    }

                    // Empty State Display
                    Item {
                        visible: accountStore.accounts.length === 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: 120

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: bridge.isLocked ? "Vault is Locked" : "No Accounts Found"
                                color: theme.textSecondary
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSizeTitle
                                font.weight: Font.Bold
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: bridge.isLocked ? "Unlock your keystore to access accounts and balances" : "Create your first Public or Shielded account to begin"
                                color: theme.textMuted
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSizeSmall
                            }
                        }
                    }
                }
            }
        }
    }
}
