import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "Profile & Accounts"
    dialogWidth: 380
    dialogHeight: Math.min(560, profileCol.implicitHeight + 120)

    required property var bridge
    required property var accountStore

    signal openCreateAccount
    signal openSettingsModal

    Theme {
        id: theme
    }

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

            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: theme.bgSurfaceSubtle
                border.color: theme.borderActive

                Text {
                    anchors.centerIn: parent
                    text: accountStore.activeAccountInitial
                    font.family: theme.fontFamily
                    font.weight: theme.weightBold
                    font.pixelSize: theme.fontSizeBody
                    color: theme.textPrimary
                }
            }

            Text {
                Layout.fillWidth: true
                text: accountStore.activeAccountName
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
            model: {
                if (!accountStore || !accountStore.accounts)
                    return [];
                var list = [];
                var active = accountStore.activeAccount;
                for (var i = 0; i < accountStore.accounts.length; i++) {
                    var acc = accountStore.accounts[i];
                    if (!active || acc.account_id !== active.account_id) {
                        list.push(acc);
                    }
                }
                return list;
            }
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
                        color: theme.accentCyan
                    }

                    Text {
                        Layout.fillWidth: true
                        text: accountStore.getAccountLabel(modelData)
                        color: accMouse.containsMouse ? theme.textPrimary : theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
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

        Text {
            visible: {
                if (!accountStore || !accountStore.accounts)
                    return true;
                var otherCount = 0;
                var active = accountStore.activeAccount;
                for (var i = 0; i < accountStore.accounts.length; i++) {
                    if (!active || accountStore.accounts[i].account_id !== active.account_id)
                        otherCount++;
                }
                return otherCount === 0;
            }
            Layout.fillWidth: true
            text: "No other accounts in keystore."
            color: theme.textMuted
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
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

        // Settings & Vault Actions
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
                text: "Lock"
                isCompact: true
                isDestructive: true
                onClicked: {
                    modal.close();
                    bridge.invoke("lockWallet", []);
                }
            }
        }
    }
}
