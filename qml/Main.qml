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
    FundingBridgeController { id: bridgeCtrl; bridge: bridge; accountStore: accountStore }
    TestimonialController { id: testimonialCtrl; bridge: bridge; accountStore: accountStore }
    ApprovalManager {
        id: approvalManager
        bridge: bridge
        accountStore: accountStore
        onPromptReceived: (prompt) => approvalModal.open()
    }

    // AUTO-LOCK IDLE TIMER (15 MINUTES)
    Timer {
        id: idleTimer
        interval: 15 * 60 * 1000 // 15 minutes
        running: bridge.isInitialized && !bridge.isLocked
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

    // ONBOARDING LIFECYCLE VIEW
    OnboardingView {
        id: onboardingView
        anchors.fill: parent
        visible: !bridge.isInitialized
        bridge: bridge
        accountStore: accountStore
        onOpenRestoreModal: restoreWalletModal.open()
    }

    // LOCK SCREEN LIFECYCLE VIEW
    LockScreenView {
        id: lockScreenView
        anchors.fill: parent
        visible: bridge.isInitialized && bridge.isLocked
        bridge: bridge
        accountStore: accountStore
        onOpenRestoreModal: restoreWalletModal.open()
    }

    // RESPONSIVE BENTO-GRID DASHBOARD VIEW
    ColumnLayout {
        id: dashboardContainer
        anchors.fill: parent
        anchors.margins: 20
        spacing: 0
        visible: bridge.isInitialized && !bridge.isLocked

        readonly property int responsiveBreakpoint: 880
        readonly property real availH: dashboardContainer.height
        readonly property bool isFlexible: availH >= 700
        readonly property real computedRow1H: isFlexible ? (availH - 12) * 0.40 : 285
        readonly property real computedRow2H: isFlexible ? (availH - 12) * 0.60 : 410

        Flickable {
            id: flickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: Math.max(width, dashboardContainer.responsiveBreakpoint)
            contentHeight: Math.max(height, mainCol.implicitHeight)
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

            ColumnLayout {
                id: mainCol
                width: Math.max(parent.width - (scrollIndicator.visible ? 10 : 0), dashboardContainer.responsiveBreakpoint)
                spacing: 12

                // ROW 1: HERO BALANCE CARD & QUICK TRANSFER CARD
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: dashboardContainer.computedRow1H
                    implicitHeight: dashboardContainer.computedRow1H
                    spacing: 12

                    BalanceView {
                        id: balanceView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        bridge: bridge
                        accountStore: accountStore
                        approvalManager: approvalManager
                        onOpenCreateAccount: createAccountModal.open()
                        onOpenSettingsModal: settingsModal.open()
                        onOpenUnlockModal: unlockModal.open()
                        onOpenProfileModal: profileModal.open()
                    }

                    TransferView {
                        id: transferView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        bridge: bridge
                        accountStore: accountStore
                        transferCtrl: transferCtrl
                        ledgerViewRef: ledgerView
                        onOpenUnlockModal: unlockModal.open()
                    }
                }

                // ROW 2: ECOSYSTEM STACK (LEFT) & ACTIVITY LEDGER (RIGHT)
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: dashboardContainer.computedRow2H
                    implicitHeight: dashboardContainer.computedRow2H
                    spacing: 12

                    // LEFT COLUMN: EmPoWer Mining & L1 Bridge + Testimonials
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        spacing: 12

                        FundingBridgeView {
                            id: bridgeView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            bridge: bridge
                            accountStore: accountStore
                            bridgeCtrl: bridgeCtrl
                            ledgerViewRef: ledgerView
                        }

                        TestimonialsView {
                            id: testimonialView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            bridge: bridge
                            accountStore: accountStore
                            testimonialCtrl: testimonialCtrl
                            ledgerViewRef: ledgerView
                        }
                    }

                    // RIGHT COLUMN: Activity Feed & Transaction History
                    ActivityLedgerView {
                        id: ledgerView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        bridge: bridge
                        accountStore: accountStore
                        onOpenTxDetailModal: function(txData) {
                            txDetailModal.txData = txData;
                            txDetailModal.open();
                        }
                    }
                }
            }
        }
    }

    // GLOBAL MODAL DIALOGS
    TxDetailModal {
        id: txDetailModal
    }

    SettingsModal {
        id: settingsModal
        bridge: bridge
        accountStore: accountStore
        onOpenRestoreWalletModal: restoreWalletModal.open()
        onOpenUnlockModal: unlockModal.open()
        onOpenIdentityModal: identityModal.open()
    }

    ProfileModal {
        id: profileModal
        bridge: bridge
        accountStore: accountStore
        approvalManager: approvalManager
        onOpenCreateAccount: createAccountModal.open()
        onOpenSettingsModal: settingsModal.open()
        onOpenUnlockModal: unlockModal.open()
        onOpenApprovalModal: approvalModal.open()
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

    ApprovalModal {
        id: approvalModal
        approvalManager: approvalManager
    }

    IdentityModal {
        id: identityModal
        bridge: bridge
        accountStore: accountStore
    }
}
