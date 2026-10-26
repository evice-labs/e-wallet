import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Item {
    id: view

    required property var bridge
    required property var accountStore

    signal openUnlockModal()
    signal openCreateWalletModal()
    signal openRestoreWalletModal()

    property int autoLockMinutes: 15
    property var activeSessions: []

    Theme { id: theme }

    Component.onCompleted: {
        loadSessions();
    }

    function loadSessions() {
        bridge.invoke("listSessions", [], function(res) {
            if (res && res.ok && Array.isArray(res.sessions)) {
                view.activeSessions = res.sessions;
            }
        });
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        RowLayout {
            Layout.fillWidth: true

            Column {
                spacing: 2
                Text {
                    text: "Security & Settings"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeHero
                    font.weight: Font.Bold
                }
                Text {
                    text: "Hardware Vault Security • Scoped dApp Permissions"
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                }
            }

            Item { Layout.fillWidth: true }

            PillBadge {
                text: bridge.isLocked ? "VAULT LOCKED" : "VAULT UNLOCKED"
                badgeColor: bridge.isLocked ? theme.accentOrange : theme.statusSuccess
            }
        }

        // Keystore Security Card
        Card {
            Layout.fillWidth: true
            Layout.preferredHeight: 190
            title: "Vault Access Control"
            subtitle: "Argon2id Master Key & Automatic Memory Purging"

            ColumnLayout {
                anchors.fill: parent
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Keystore Encryption State"
                            color: theme.textPrimary
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeBody
                            font.weight: Font.Bold
                        }
                        Text {
                            text: bridge.isLocked ? "Secret keys are cleared from volatile RAM memory" : "Keys decrypted in local host memory for active session"
                            color: theme.textSecondary
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeSmall
                        }
                    }

                    Button {
                        text: bridge.isLocked ? "Unlock Vault" : "Lock Vault Now"
                        isPrimary: bridge.isLocked
                        isDestructive: !bridge.isLocked
                        onClicked: {
                            if (bridge.isLocked) {
                                view.openUnlockModal();
                            } else {
                                bridge.invoke("lockWallet", []);
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: theme.borderSubtle
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: "Restore or Initialize Another Vault"
                            color: theme.textPrimary
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeBody
                            font.weight: Font.Bold
                        }
                        Text {
                            text: "Import existing BIP-39 mnemonic seed phrase or create a fresh keystore"
                            color: theme.textSecondary
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeSmall
                        }
                    }

                    Button {
                        text: "Restore Phrase"
                        isPrimary: false
                        isCompact: true
                        onClicked: view.openRestoreWalletModal()
                    }

                    Button {
                        text: "New Keystore"
                        isPrimary: false
                        isCompact: true
                        onClicked: view.openCreateWalletModal()
                    }
                }
            }
        }

        // Network & Telemetry Information Card
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Network Connectivity & Specifications"
            subtitle: "Logos Execution Zone • LP-0021 Native Provider Module"

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                InsetPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 88

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "Active Network:"
                                color: theme.textSecondary
                                font.family: theme.fontMono
                                font.pixelSize: theme.fontSizeSmall
                            }
                            Text {
                                text: bridge.currentNetwork
                                color: theme.textPrimary
                                font.family: theme.fontMono
                                font.pixelSize: theme.fontSizeSmall
                                font.weight: Font.Bold
                            }
                            Item { Layout.fillWidth: true }
                            PillBadge {
                                text: "Testnet 0.4 Standard"
                                badgeColor: theme.statusSuccess
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "LEZ Sequencer:"
                                color: theme.textSecondary
                                font.family: theme.fontMono
                                font.pixelSize: theme.fontSizeSmall
                            }
                            Text {
                                text: "https://testnet.lez.logos.co"
                                color: theme.textPrimary
                                font.family: theme.fontMono
                                font.pixelSize: theme.fontSizeSmall
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    PillBadge {
                        text: "Argon2id KDF"
                        badgeColor: theme.statusPublic
                    }
                    PillBadge {
                        text: "AES-256-GCM Vault"
                        badgeColor: theme.statusPublic
                    }
                    PillBadge {
                        text: "BIP-39 Mnemonic"
                        badgeColor: theme.statusPublic
                    }
                    PillBadge {
                        text: "Zero-Telemetry Invariant"
                        badgeColor: theme.statusSuccess
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }
    }
}
