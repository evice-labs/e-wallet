import QtQuick
import QtQuick.Layouts
import "theme"
import "state"
import "views"
import "modals"

Rectangle {
    id: root

    width: 1024
    height: 720
    color: theme.bgCanvas

    Theme {
        id: theme
    }
    WalletBridge {
        id: bridge
    }
    AccountStore {
        id: accountStore
        bridge: bridge
        onDepositDetected: (accountLabel, amountStr, accountId, isPrivate) => {
            if (ledgerView)
                ledgerView.addActivity(accountLabel, "Deposit", "Transfers", "+" + amountStr, "Inbound Transfer (Deposit)", true, "", "0 (Paid by Sender)", "-", "External ➝ " + (isPrivate ? "Private/" : "Public/") + accountId.substring(0, 8) + "...", accountId, "0");
        }
        onBalanceChanged: (accountId, oldBalance, newBalance) => {
            if (ledgerView)
                ledgerView.markAccountPendingTransactionsConfirmed(accountId);
        }
    }

    TransferController {
        id: transferCtrl
        bridge: bridge
        accountStore: accountStore
    }
    FundingBridgeController {
        id: bridgeCtrl
        bridge: bridge
        accountStore: accountStore
    }
    TestimonialController {
        id: testimonialCtrl
        bridge: bridge
        accountStore: accountStore
    }
    ApprovalManager {
        id: approvalManager
        bridge: bridge
        accountStore: accountStore
        onPromptReceived: prompt => approvalModal.open()
    }

    // AUTO-LOCK IDLE TIMER (15 MINUTES)
    Timer {
        id: idleTimer
        interval: 15 * 60 * 1000
        running: bridge.isInitialized && !bridge.isLocked
        onTriggered: bridge.invoke("lockWallet", [])
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        propagateComposedEvents: true
        onPositionChanged: mouse => {
            if (idleTimer.running)
                idleTimer.restart();
        }
        onPressed: mouse => {
            if (idleTimer.running)
                idleTimer.restart();
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
        visible: bridge.isInitialized && (bridge.isLocked || !accountStore.isReady)
        bridge: bridge
        accountStore: accountStore
        onOpenRestoreModal: restoreWalletModal.open()
    }

    // RESPONSIVE DASHBOARD VIEW
    ColumnLayout {
        id: dashboardContainer
        anchors.fill: parent
        anchors.margins: 20
        spacing: 0
        visible: bridge.isInitialized && !bridge.isLocked && accountStore.isReady

        readonly property int responsiveBreakpoint: 880
        readonly property bool isNarrow: width < responsiveBreakpoint
        readonly property bool isFlexible: height >= 700
        readonly property real computedRow1H: isFlexible ? (height - 12) * 0.40 : 285
        readonly property real computedRow2H: isFlexible ? (height - 12) * 0.60 : 410

        // SCROLLABLE BODY CONTAINER
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Flickable {
                id: flickable
                anchors.fill: parent
                anchors.rightMargin: scrollTrack.visible ? 10 : 0
                contentWidth: width
                contentHeight: mainCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                Behavior on contentY {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                WheelHandler {
                    id: wheelHandler
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        var step = (event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y) * 1.0;
                        var maxScroll = Math.max(0, flickable.contentHeight - flickable.height);
                        flickable.contentY = Math.max(0, Math.min(maxScroll, flickable.contentY - step));
                    }
                }

                ColumnLayout {
                    id: mainCol
                    width: flickable.width
                    spacing: 12

                    // SECTION 1: BALANCE & TRANSFER (Grid in Desktop / Stacked in Narrow)
                    GridLayout {
                        id: row1Grid
                        Layout.fillWidth: true
                        columns: dashboardContainer.isNarrow ? 1 : 2
                        columnSpacing: 12
                        rowSpacing: 12
                        Layout.preferredHeight: dashboardContainer.isNarrow ? -1 : dashboardContainer.computedRow1H

                        BalanceView {
                            id: balanceView
                            Layout.fillWidth: true
                            Layout.fillHeight: !dashboardContainer.isNarrow
                            Layout.preferredHeight: dashboardContainer.isNarrow ? implicitHeight : -1
                            Layout.preferredWidth: dashboardContainer.isNarrow ? -1 : 1
                            bridge: bridge
                            accountStore: accountStore
                            approvalManager: approvalManager
                            onOpenCreateAccount: createAccountModal.open()
                            onOpenSettingsModal: settingsModal.open()
                            onOpenUnlockModal: unlockModal.open()
                            onOpenProfileModal: profileModal.open()
                            onOpenAddTokenModal: addTokenModal.open()
                        }

                        TransferView {
                            id: transferView
                            Layout.fillWidth: true
                            Layout.fillHeight: !dashboardContainer.isNarrow
                            Layout.preferredHeight: dashboardContainer.isNarrow ? implicitHeight : -1
                            Layout.preferredWidth: dashboardContainer.isNarrow ? -1 : 1
                            bridge: bridge
                            accountStore: accountStore
                            transferCtrl: transferCtrl
                            ledgerViewRef: ledgerView
                            onOpenUnlockModal: unlockModal.open()
                        }
                    }

                    // SECTION 2: ECOSYSTEM (MINING/TESTIMONIALS) & ACTIVITY LEDGER
                    GridLayout {
                        id: row2Grid
                        Layout.fillWidth: true
                        columns: dashboardContainer.isNarrow ? 1 : 2
                        columnSpacing: 12
                        rowSpacing: 12
                        Layout.preferredHeight: dashboardContainer.isNarrow ? -1 : dashboardContainer.computedRow2H

                        // LEFT COLUMN: EmPoWer Mining & L1 Bridge + Testimonials
                        ColumnLayout {
                            id: ecosystemCol
                            Layout.fillWidth: true
                            Layout.fillHeight: !dashboardContainer.isNarrow
                            Layout.preferredWidth: dashboardContainer.isNarrow ? -1 : 1
                            spacing: 12

                            FundingBridgeView {
                                id: bridgeView
                                Layout.fillWidth: true
                                Layout.fillHeight: !dashboardContainer.isNarrow
                                Layout.preferredHeight: dashboardContainer.isNarrow ? implicitHeight : -1
                                bridge: bridge
                                accountStore: accountStore
                                bridgeCtrl: bridgeCtrl
                                ledgerViewRef: ledgerView
                            }

                            TestimonialsView {
                                id: testimonialView
                                Layout.fillWidth: true
                                Layout.fillHeight: !dashboardContainer.isNarrow
                                Layout.preferredHeight: dashboardContainer.isNarrow ? implicitHeight : -1
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
                            Layout.fillHeight: !dashboardContainer.isNarrow
                            Layout.preferredHeight: dashboardContainer.isNarrow ? implicitHeight : -1
                            Layout.preferredWidth: dashboardContainer.isNarrow ? -1 : 1
                            bridge: bridge
                            accountStore: accountStore
                            onOpenTxDetailModal: function (txData) {
                                txDetailModal.txData = txData;
                                txDetailModal.open();
                            }
                        }
                    }
                }
            }

            // STATIC VIEWPORT SCROLLBAR TRACK & THUMB
            Rectangle {
                id: scrollTrack
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 2
                anchors.bottomMargin: 2
                width: 4
                radius: 2
                color: theme.bgSurfaceSubtle
                visible: flickable.visibleArea.heightRatio < 1.0
                z: 20

                Rectangle {
                    id: scrollThumb
                    width: parent.width
                    height: Math.max(30, flickable.visibleArea.heightRatio * scrollTrack.height)
                    y: flickable.visibleArea.yPosition * scrollTrack.height
                    radius: 2
                    color: theme.borderActive
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    function updateScroll(y) {
                        var maxRatio = 1.0 - flickable.visibleArea.heightRatio;
                        var ratio = Math.max(0, Math.min(maxRatio, (y - scrollThumb.height / 2) / scrollTrack.height));
                        flickable.contentY = (ratio / maxRatio) * Math.max(0, flickable.contentHeight - flickable.height);
                    }
                    onPositionChanged: mouse => {
                        if (pressed)
                            updateScroll(mouse.y);
                    }
                    onPressed: mouse => updateScroll(mouse.y)
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
    ApprovalModal {
        id: approvalModal
        approvalManager: approvalManager
    }
    IdentityModal {
        id: identityModal
        bridge: bridge
        accountStore: accountStore
    }
    AddTokenModal {
        id: addTokenModal
        accountStore: accountStore
    }
}
