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

    // ── Auto-Lock Idle Timer (15 Minutes) ─────────────────────
    Timer {
        id: idleTimer
        interval: 15 * 60 * 1000 // 15 minutes
        running: !bridge.isLocked
        repeat: false
        onTriggered: {
            console.log("[AutoLock] 15 minutes idle timeout reached, locking wallet keystore");
            bridge.invoke("lockWallet", []);
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        propagateComposedEvents: true
        onPositionChanged: (mouse) => {
            if (idleTimer.running) idleTimer.restart();
        }
        onPressed: (mouse) => {
            if (idleTimer.running) idleTimer.restart();
            mouse.accepted = false;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ── Unified Bento-Grid Dashboard Container ────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: flickable
                anchors.fill: parent
                contentWidth: width
                contentHeight: mainCol.implicitHeight + 24
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // Minimalist Scroll Indicator
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

                // Global Dismiss Overlay for Balance Profile Dropdown
                MouseArea {
                    anchors.fill: parent
                    z: 50
                    visible: balanceView.isProfileMenuOpen
                    onClicked: {
                        balanceView.isProfileMenuOpen = false;
                        balanceView.isCascadeExpanded = false;
                    }
                }

                ColumnLayout {
                    id: mainCol
                    width: parent.width - (scrollIndicator.visible ? 10 : 0)
                    spacing: 16

                    // ══════════════════════════════════════════════════════════
                    // ROW 1: 1. HERO BALANCE CARD & 2. QUICK TRANSFER CARD
                    // ══════════════════════════════════════════════════════════
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        BalanceView {
                            id: balanceView
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.alignment: Qt.AlignTop
                            bridge: bridge
                            accountStore: accountStore
                            onOpenCreateAccount: createAccountModal.open()
                            onOpenSettingsModal: settingsModal.open()
                            onOpenUnlockModal: unlockModal.open()
                        }

                        TransferView {
                            id: transferView
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.alignment: Qt.AlignTop
                            bridge: bridge
                            accountStore: accountStore
                            transferCtrl: transferCtrl
                            onOpenUnlockModal: unlockModal.open()
                        }
                    }

                    // ══════════════════════════════════════════════════════════
                    // ROW 2: 3. FAUCET & MINING & 4. TESTIMONIAL WIDGET
                    // ══════════════════════════════════════════════════════════
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        FundingBridgeView {
                            id: faucetView
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.alignment: Qt.AlignTop
                            bridge: bridge
                            accountStore: accountStore
                        }

                        TestimonialsView {
                            id: testimonialView
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.alignment: Qt.AlignTop
                            bridge: bridge
                            accountStore: accountStore
                        }
                    }

                    // ══════════════════════════════════════════════════════════
                    // ROW 3: 5. ACTIVITY FEED & TRANSACTION LEDGER (Full Width)
                    // ══════════════════════════════════════════════════════════
                    ActivityLedgerView {
                        id: ledgerView
                        Layout.fillWidth: true
                        bridge: bridge
                        accountStore: accountStore
                    }
                }
            }
        }

        // ── Tactile Footer Telemetry Bar ──────────────────────────
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

    // ── Global Modal Dialogs ──────────────────────────────────
    SettingsModal {
        id: settingsModal
        bridge: bridge
        accountStore: accountStore
        onOpenRestoreWalletModal: restoreWalletModal.open()
        onOpenUnlockModal: unlockModal.open()
    }

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
