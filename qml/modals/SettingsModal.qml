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

    dialogWidth: 540
    dialogHeight: 460
    title: "Wallet & Network Settings"

    Theme { id: theme }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        // Keystore Information
        Card {
            Layout.fillWidth: true
            title: "Security & Keystore"
            subtitle: "Argon2id Encrypted AES-256-GCM Vault"

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
                        text: modal.accountStore.activeAccount ? modal.accountStore.activeAccount.label : "alice.lez"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: Font.DemiBold
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Address:"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: {
                            var addr = modal.accountStore.activeAccount ? modal.accountStore.activeAccount.address : "lez1alice89q7v2..."
                            if (addr.length > 20) return addr.substring(0, 8) + "..." + addr.substring(addr.length - 8);
                            return addr;
                        }
                        color: theme.textPrimary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
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
                    PillBadge {
                        text: modal.bridge.isLocked ? "LOCKED" : "UNLOCKED"
                        badgeColor: modal.bridge.isLocked ? theme.statusDanger : theme.statusSuccess
                    }
                }
            }
        }

        // Network Configuration
        Card {
            Layout.fillWidth: true
            title: "Network Connection"
            subtitle: "Decentralized LEZ Sequencer Node"

            ColumnLayout {
                width: parent.width
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Sequencer RPC:"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "https://testnet.lez.logos.co"
                        color: theme.textPrimary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Network Status:"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item { Layout.fillWidth: true }
                    PillBadge {
                        text: "ONLINE • 14ms"
                        badgeColor: theme.statusSuccess
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Action Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: "Restore from Seed"
                isCompact: true
                onClicked: {
                    modal.close();
                    modal.openRestoreWalletModal();
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Close"
                isPrimary: true
                isCompact: true
                onClicked: modal.close()
            }
        }
    }
}
