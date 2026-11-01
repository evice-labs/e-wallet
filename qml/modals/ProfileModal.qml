import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "Profile & Accounts"
    dialogWidth: 380
    dialogHeight: Math.min(580, profileCol.implicitHeight + 120)

    required property var bridge
    required property var accountStore
    required property var approvalManager

    signal openCreateAccount()
    signal openSettingsModal()
    signal openUnlockModal()
    signal openApprovalModal()

    Theme { id: theme }

    ColumnLayout {
        id: profileCol
        anchors.fill: parent
        spacing: 8

        // Header: Active Account details
        Text {
            text: "ACTIVE ACCOUNT"
            color: theme.textMuted
            font.family: theme.fontMono
            font.pixelSize: theme.fontSizeTiny
            font.weight: Font.Bold
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: accountStore.activeAccount && accountStore.activeAccount.label ? accountStore.activeAccount.label : "alice.lez"
                color: theme.textPrimary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeBody
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                text: (accountStore.activeAccount && accountStore.activeAccount.is_private) ? "SHIELDED" : "PUBLIC"
                color: (accountStore.activeAccount && accountStore.activeAccount.is_private) ? theme.statusShielded : theme.statusPublic
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTiny
                font.weight: Font.Bold
            }
        }

        // dApp Approval Request Notification / Preview List (Max 3)
        Repeater {
            model: approvalManager ? approvalManager.pendingRequests.slice(0, 3) : []

            delegate: Rectangle {
                Layout.fillWidth: true
                implicitHeight: dappPreviewCol.implicitHeight + 14
                radius: theme.radiusButton
                color: theme.bgSurfaceSubtle
                border.color: theme.borderActive
                border.width: 1

                ColumnLayout {
                    id: dappPreviewCol
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: theme.accentCyan
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "dApp Request"
                            color: theme.textPrimary
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeTiny
                            font.weight: Font.Bold
                        }

                        Text {
                            text: modelData.verification_status || "VERIFIED"
                            color: theme.statusSuccess
                            font.family: theme.fontMono
                            font.pixelSize: theme.fontSizeTiny
                            font.weight: Font.Bold
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: (modelData.dapp_name || "Unknown dApp") + " • " + (modelData.grant_kind || "GrantKind::Propose")
                        color: theme.textSecondary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeTiny
                        elide: Text.ElideRight
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "View dApp Request"
                        isCompact: true
                        customHeight: 26
                        onClicked: {
                            modal.close();
                            approvalManager.selectAndReviewRequest(modelData);
                            modal.openApprovalModal();
                        }
                    }
                }
            }
        }

        // Queue Overflow Indicator (when more than 3 requests in queue)
        Rectangle {
            Layout.fillWidth: true
            height: 24
            radius: theme.radiusButton
            color: Qt.rgba(1.0, 0.52, 0.22, 0.12)
            border.color: theme.accentOrange
            border.width: 1
            visible: approvalManager && approvalManager.pendingRequests.length > 3

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: theme.accentOrange
                }

                Text {
                    text: approvalManager ? ("+" + (approvalManager.pendingRequests.length - 3) + " more request(s) in queue") : ""
                    color: theme.accentOrange
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTiny
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Shifts in order on sign/reject"
                    color: theme.textMuted
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTiny
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // Quick Actions: Account List
        Text {
            text: "SWITCH ACCOUNT"
            color: theme.textMuted
            font.family: theme.fontMono
            font.pixelSize: theme.fontSizeTiny
            font.weight: Font.Bold
        }

        Repeater {
            model: accountStore.accounts
            delegate: Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: theme.radiusButton
                color: accMouse.containsMouse ? theme.bgSurfaceSubtle : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 8

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: modelData === accountStore.activeAccount ? theme.statusSuccess : "transparent"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.label || "Account"
                        color: modelData === accountStore.activeAccount ? theme.textPrimary : (accMouse.containsMouse ? theme.textPrimary : theme.textSecondary)
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: modelData === accountStore.activeAccount ? Font.Bold : Font.Normal
                        elide: Text.ElideRight
                    }

                    Text {
                        text: modelData.is_private ? "Shielded" : "Public"
                        color: modelData.is_private ? theme.statusShielded : theme.statusPublic
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.Bold
                    }
                }

                MouseArea {
                    id: accMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        accountStore.selectAccount(modelData);
                    }
                }
            }
        }

        // Button: + Add New Account
        Rectangle {
            Layout.fillWidth: true
            height: 30
            radius: theme.radiusButton
            color: addMouse.containsMouse ? theme.bgSurfaceSubtle : "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    text: "+ Add New Account"
                    color: addMouse.containsMouse ? theme.textPrimary : theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                    font.weight: Font.DemiBold
                }
            }

            MouseArea {
                id: addMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    modal.close();
                    modal.openCreateAccount();
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // Settings & Vault Actions (Inside Card)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                Layout.fillWidth: true
                text: "Settings"
                isCompact: true
                onClicked: {
                    modal.close();
                    modal.openSettingsModal();
                }
            }

            Button {
                Layout.fillWidth: true
                text: bridge.isLocked ? "Unlock" : "Lock"
                isCompact: true
                isDestructive: !bridge.isLocked
                isPrimary: bridge.isLocked
                onClicked: {
                    modal.close();
                    if (bridge.isLocked) {
                        modal.openUnlockModal();
                    } else {
                        bridge.invoke("lockWallet", []);
                    }
                }
            }
        }
    }
}
