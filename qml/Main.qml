import QtQuick
import QtQuick.Layouts
import "theme"
import "controls"
import "state"
import "views"
import "modals"

Rectangle {
    id: root

    width: 1024
    height: 720
    color: theme.bgCanvas

    Theme { id: theme }
    WalletBridge { id: bridge }
    AccountStore { id: accountStore; bridge: bridge }
    TransferController { id: transferCtrl; bridge: bridge; accountStore: accountStore }

    property string currentTab: "dashboard"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 18

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
                isPrimary: bridge.isLocked
                isDestructive: !bridge.isLocked
                onClicked: {
                    if (bridge.isLocked) {
                        unlockModal.open();
                    } else {
                        bridge.invoke("lockWallet", []);
                    }
                }
            }
        }

        // Active View Container (Decoupled Modular Architecture)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            DashboardView {
                anchors.fill: parent
                visible: root.currentTab === "dashboard"
                bridge: bridge
                accountStore: accountStore
                onOpenCreateAccount: createAccountModal.open()
                onOpenAccountDetail: function(acc) {
                    accountDetailModal.account = acc;
                    accountDetailModal.open();
                }
                onNavigateTab: function(tabName) {
                    root.currentTab = tabName;
                }
            }

            TransferView {
                anchors.fill: parent
                visible: root.currentTab === "transfer"
                bridge: bridge
                accountStore: accountStore
                transferCtrl: transferCtrl
            }

            FundingBridgeView {
                anchors.fill: parent
                visible: root.currentTab === "funding"
                bridge: bridge
                accountStore: accountStore
            }

            TestimonialsView {
                anchors.fill: parent
                visible: root.currentTab === "testimonials"
                bridge: bridge
                accountStore: accountStore
            }

            SettingsView {
                anchors.fill: parent
                visible: root.currentTab === "settings"
                bridge: bridge
                accountStore: accountStore
                onOpenUnlockModal: unlockModal.open()
                onOpenCreateWalletModal: createWalletModal.open()
                onOpenRestoreWalletModal: restoreWalletModal.open()
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

    // Global Modal Presenters
    UnlockModal {
        id: unlockModal
        bridge: bridge
    }

    CreateWalletModal {
        id: createWalletModal
        bridge: bridge
        accountStore: accountStore
    }

    RestoreWalletModal {
        id: restoreWalletModal
        bridge: bridge
        accountStore: accountStore
    }

    CreateAccountModal {
        id: createAccountModal
        accountStore: accountStore
    }

    AccountDetailModal {
        id: accountDetailModal
        accountStore: accountStore
    }
}
