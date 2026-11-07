import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Card {
    id: bridgeCard

    required property var bridge
    required property var accountStore
    property var bridgeCtrl: null
    property var ledgerViewRef: null
    property string activeAction: "mining" // "mining" | "bridge"

    readonly property bool isPrivateActive: accountStore.activeAccount ? (accountStore.activeAccount.is_private === true || accountStore.activeAccount.privacy === "private") : false

    implicitHeight: 186
    title: "EmPoWer Mining & L1 → LEZ Bridge"

    Connections {
        target: bridgeCtrl
        function onDepositSuccess(amount, txHash) {
            if (bridgeCard.ledgerViewRef) {
                var acc = accountStore.activeAccount;
                var label = acc ? acc.label : "Primary Account";
                var targetId = acc ? acc.account_id : "";
                var cleanedAmt = String(amount).replace(/,/g, "").trim();
                var formattedAmt = accountStore ? accountStore.formatThousands(cleanedAmt) : cleanedAmt;
                bridgeCard.ledgerViewRef.addActivity(label, "Channel Bridge", "Transfers", "+" + formattedAmt, "L1 → LEZ Channel Deposit", true, txHash || "Pending Confirmation", "0 (Channel Inscription)", "-", "Logos L1 ➝ LEZ Channel", targetId, "0");
            }
            resetActionTimer.restart();
        }
    }

    Timer {
        id: resetActionTimer
        interval: 1800
        repeat: false
        onTriggered: {
            bridgeCard.activeAction = "mining";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // BODY: DUAL METRIC PANELS
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Panel 1: Miner Status & Telemetry
            InsetPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 64

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: "MINER STATUS & HASHRATE"
                        color: theme.textSecondary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeTiny
                    }

                    Text {
                        text: (bridgeCtrl && bridgeCtrl.isMining) ? (bridgeCtrl.hashrate + " H/s (ACTIVE)") : "OFFLINE"
                        color: (bridgeCtrl && bridgeCtrl.isMining) ? theme.statusSuccess : theme.textMuted
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeBody + 2
                        font.weight: Font.Bold
                    }
                }
            }

            // Panel 2: Unbridged Mined L1 Notes
            InsetPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 64

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4

                    Text {
                        text: "UNBRIDGED L1 MINED BALANCE"
                        color: theme.accentOrange
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeTiny
                    }

                    Text {
                        text: bridgeCtrl ? bridgeCtrl.unbridgedL1Tokens : "0.00 LOGOS"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeBody + 2
                        font.weight: Font.Bold
                    }
                }
            }
        }

        // FLEXIBLE EXPANDING SPACER
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // SKEUOMORPHIC DIVIDER
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // FOOTER: PoW Telemetry Status (Left) & Segmented Dark Action Console (Right)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Left: Real-Time PoW Node Telemetry
            RowLayout {
                spacing: 6
                Layout.fillWidth: true

                Rectangle {
                    implicitWidth: 6
                    implicitHeight: 6
                    radius: 3
                    color: bridgeCard.isPrivateActive ? theme.accentOrange : ((bridgeCtrl && bridgeCtrl.isMining) ? theme.statusSuccess : theme.textMuted)
                }

                Text {
                    text: bridgeCard.isPrivateActive ? "SHIELDED ACCOUNT • PUBLIC BRIDGE LOCKED" : ((bridgeCtrl && bridgeCtrl.isMining) ? ("POW ACTIVE • " + bridgeCtrl.hashrate + " H/S") : ((bridgeCtrl && !bridgeCtrl.isSuccessStatus && bridgeCtrl.statusMessage.length > 0) ? bridgeCtrl.statusMessage : "NODE IDLE • SHA-256"))
                    color: bridgeCard.isPrivateActive ? theme.accentOrange : ((bridgeCtrl && bridgeCtrl.isMining) ? theme.statusSuccess : ((bridgeCtrl && !bridgeCtrl.isSuccessStatus && bridgeCtrl.statusMessage.length > 0) ? theme.statusDanger : theme.textMuted))
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTiny
                    font.weight: (bridgeCtrl && bridgeCtrl.isMining || bridgeCard.isPrivateActive) ? Font.Bold : Font.Normal
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Right: Tactile Segmented Pill Console
            SegmentedBar {
                id: actionConsole
                Layout.alignment: Qt.AlignVCenter

                TabButton {
                    id: miningSegment
                    readonly property bool canMine: !bridgeCard.isPrivateActive
                    customWidth: 112
                    text: (bridgeCtrl && bridgeCtrl.isMining) ? "Stop Mining" : (bridgeCard.isPrivateActive ? "Public Only" : "Start Mining")
                    isActive: bridgeCard.activeAction === "mining"
                    isDestructive: (bridgeCtrl && bridgeCtrl.isMining) && bridgeCard.activeAction === "mining"
                    isMuted: bridgeCard.isPrivateActive && !(bridgeCtrl && bridgeCtrl.isMining)
                    inactiveTextColor: bridgeCard.isPrivateActive ? theme.accentOrange : "transparent"
                    opacity: (bridgeCtrl && bridgeCtrl.isMining) ? 1.0 : (miningSegment.canMine ? 1.0 : 0.35)
                    cursorShape: (bridgeCtrl && bridgeCtrl.isMining) ? Qt.PointingHandCursor : (miningSegment.canMine ? Qt.PointingHandCursor : Qt.ForbiddenCursor)
                    onClicked: {
                        if (bridgeCard.isPrivateActive && (!bridgeCtrl || !bridgeCtrl.isMining)) {
                            if (bridgeCtrl) {
                                bridgeCtrl.statusMessage = "Notice: EmPoWer Mining only supports Public accounts. Switch to a Public account to mine.";
                                bridgeCtrl.isSuccessStatus = false;
                            }
                            return;
                        }
                        bridgeCard.activeAction = "mining";
                        if (bridgeCtrl) {
                            if (bridgeCtrl.isMining) {
                                bridgeCtrl.stopMining();
                            } else {
                                bridgeCtrl.startMining();
                            }
                        }
                    }
                }

                TabButton {
                    id: bridgeSegment
                    readonly property bool canBridge: !bridge.isLocked && accountStore.activeAccount !== null && !bridgeCard.isPrivateActive && bridgeCtrl !== null && bridgeCtrl.hasUnbridgedTokens && !bridgeCtrl.isDepositing
                    customWidth: 115
                    text: (bridgeCtrl && bridgeCtrl.isDepositing) ? "Bridging..." : (bridgeCard.isPrivateActive ? "Public Only" : "Bridge Tokens")
                    isActive: bridgeCard.activeAction === "bridge"
                    isMuted: bridgeCard.isPrivateActive
                    inactiveTextColor: bridgeCard.isPrivateActive ? theme.accentOrange : "transparent"
                    opacity: bridgeCard.activeAction === "bridge" ? 1.0 : (bridgeSegment.canBridge ? 1.0 : (bridgeCard.isPrivateActive ? 0.35 : 0.45))
                    cursorShape: bridgeSegment.canBridge ? Qt.PointingHandCursor : (bridgeCard.isPrivateActive ? Qt.ForbiddenCursor : Qt.ArrowCursor)
                    onClicked: {
                        if (bridgeCard.isPrivateActive) {
                            if (bridgeCtrl) {
                                bridgeCtrl.statusMessage = "Notice: L1 Channel Bridge only supports Public accounts. Switch to a Public account to bridge tokens.";
                                bridgeCtrl.isSuccessStatus = false;
                            }
                        } else if (bridgeSegment.canBridge) {
                            bridgeCard.activeAction = "bridge";
                            if (bridgeCtrl) {
                                bridgeCtrl.depositToLez();
                            }
                        }
                    }
                }
            }
        }
    }
}
