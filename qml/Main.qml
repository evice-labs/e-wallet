import QtQuick
import QtQuick.Layouts
import "theme"
import "controls"
import "state"

Rectangle {
    id: root

    width: 1024
    height: 720
    color: theme.bgCanvas

    Theme { id: theme }
    WalletBridge { id: bridge }

    property string currentTab: "dashboard"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 24

        // Top Navigation Header Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 16

            Text {
                text: "Evice Vault"
                color: theme.textPrimary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTitle
                font.weight: Font.Bold
            }

            PillBadge {
                text: bridge.isHostAvailable ? "Basecamp Connected" : "Local Standalone Preview"
                badgeColor: bridge.isHostAvailable ? theme.statusSuccess : theme.statusPublic
            }

            Item { Layout.fillWidth: true }

            // Segmented Top Navigation (Strict Zero-Icon Rule)
            Row {
                spacing: 6
                TabButton {
                    text: "Dashboard"
                    isActive: root.currentTab === "dashboard"
                    onClicked: root.currentTab = "dashboard"
                }
                TabButton {
                    text: "Transfer"
                    isActive: root.currentTab === "transfer"
                    onClicked: root.currentTab = "transfer"
                }
                TabButton {
                    text: "Funding & Bridge"
                    isActive: root.currentTab === "funding"
                    onClicked: root.currentTab = "funding"
                }
                TabButton {
                    text: "Testimonials"
                    isActive: root.currentTab === "testimonials"
                    onClicked: root.currentTab = "testimonials"
                }
                TabButton {
                    text: "Settings"
                    isActive: root.currentTab === "settings"
                    onClicked: root.currentTab = "settings"
                }
            }

            Button {
                text: bridge.isLocked ? "Unlock Vault" : "Lock Vault"
                isCompact: true
                onClicked: {
                    if (bridge.isLocked) {
                        bridge.invoke("unlockWallet", ["password123"]);
                    } else {
                        bridge.invoke("lockWallet", []);
                    }
                }
            }
        }

        // Usage & Action Hero Section (Reference Matched)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 14

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

                // Action Buttons with Bevel Specular Highlights
                Button {
                    text: "Documentation"
                    isPrimary: false
                    onClicked: console.log("Documentation opened")
                }

                Button {
                    text: "Create Account"
                    isPrimary: true
                    onClicked: {
                        bridge.invoke("createPublicAccount", ["Secondary Account"]);
                    }
                }
            }

            // Tactile Recessed Grooved Progress Bar (Reference Matched)
            ProgressBar {
                Layout.fillWidth: true
                title: "Logos testnet 0.4 epoch quota used"
                readout: "1 / 3,000"
                value: 1.0 / 3000.0
                barColor: theme.accentOrange
            }
        }

        // Main View Workspace Panel
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Hardware Keystore & Active Balance"
            subtitle: "Logos Execution Zone • Pinned to devnet & testnet 0.4 standard"

            ColumnLayout {
                anchors.fill: parent
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    InsetPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 90

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "PRIMARY VAULT BALANCE"
                                color: theme.textSecondary
                                font.family: theme.fontMono
                                font.pixelSize: theme.fontSizeSmall
                                font.weight: Font.Medium
                            }

                            Text {
                                text: "12,500.00 LEZ"
                                color: theme.textPrimary
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSizeTitle + 4
                                font.weight: Font.Bold
                            }
                        }
                    }

                    InsetPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 90

                        Column {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: "SHIELDED ZERO-KNOWLEDGE BALANCE"
                                color: theme.statusShielded
                                font.family: theme.fontMono
                                font.pixelSize: theme.fontSizeSmall
                                font.weight: Font.Medium
                            }

                            Text {
                                text: "8,400.00 LEZ"
                                color: theme.textPrimary
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSizeTitle + 4
                                font.weight: Font.Bold
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    PillBadge {
                        text: "Public Transparent Account"
                        badgeColor: theme.statusPublic
                    }

                    PillBadge {
                        text: "Shielded ZK Circuit Account"
                        badgeColor: theme.statusShielded
                    }

                    PillBadge {
                        text: "Program Registry LP-0023 Verified"
                        badgeColor: theme.statusSuccess
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Transfer Assets"
                        isPrimary: true
                        isCompact: true
                        onClicked: root.currentTab = "transfer"
                    }

                    Button {
                        text: "Mine EmPoWer"
                        isPrimary: false
                        isCompact: true
                        onClicked: root.currentTab = "funding"
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // Tactile Footer Telemetry Bar
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "LEZ Sequencer: https://testnet.lez.logos.co"
                color: theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "BIP-39 Keystore: AES-256-GCM (Argon2id Encrypted)"
                color: theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
            }
        }
    }
}
