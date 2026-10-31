import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    required property var bridge
    required property var accountStore

    signal openRestoreWalletModal()
    signal openUnlockModal()
    signal openIdentityModal()

    dialogWidth: 500
    dialogHeight: 310
    title: "Wallet Settings"

    Theme { id: theme }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // SECURITY & KEYSTORE
        Card {
            Layout.fillWidth: true
            title: "Security & Keystore"

            ColumnLayout {
                width: parent.width
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Active Account:"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: modal.accountStore.activeAccount ? modal.accountStore.activeAccount.label : "Primary Account"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: Font.DemiBold
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Vault Status:"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: modal.bridge.isLocked ? "LOCKED" : "UNLOCKED"
                        color: modal.bridge.isLocked ? theme.statusDanger : theme.statusSuccess
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.Bold
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        // STATIC MODAL FOOTER ACTIONS
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                Layout.fillWidth: true
                text: "Restore from Seed"
                isCompact: true
                onClicked: {
                    modal.close();
                    modal.openRestoreWalletModal();
                }
            }

            Button {
                Layout.fillWidth: true
                text: modal.bridge.isLocked ? "Unlock Vault" : "Lock Vault"
                isCompact: true
                isDestructive: !modal.bridge.isLocked
                isPrimary: modal.bridge.isLocked
                onClicked: {
                    modal.close();
                    if (modal.bridge.isLocked) {
                        modal.openUnlockModal();
                    } else {
                        modal.bridge.invoke("lockWallet", []);
                    }
                }
            }
        }
    }
}
