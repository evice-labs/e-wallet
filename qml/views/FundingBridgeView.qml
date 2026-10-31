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

    implicitHeight: 186
    title: "EmPoWer Mining & L1 → LEZ Bridge"

    Connections {
        target: bridgeCtrl
        function onDepositSuccess(amount, txHash) {
            if (bridgeCard.ledgerViewRef) {
                var acc = accountStore.activeAccount;
                var label = acc ? acc.label : "Primary Account";
                bridgeCard.ledgerViewRef.addActivity(
                    label,
                    "Channel Bridge",
                    "Transfers",
                    "+" + amount + " LEZ",
                    "L1 → LEZ Channel Deposit",
                    true,
                    txHash || "0x3f9e8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f",
                    "Channel Inscription (L1 Bridge)",
                    43580,
                    "Logos L1 ➝ LEZ Channel"
                );
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
                        text: (bridgeCtrl && bridgeCtrl.isMining) ?
                              (bridgeCtrl.hashrate + " H/s (ACTIVE)") : "OFFLINE"
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
                    color: (bridgeCtrl && bridgeCtrl.isMining) ? theme.statusSuccess : theme.textMuted
                }

                Text {
                    text: (bridgeCtrl && bridgeCtrl.isMining) ?
                          ("POW ACTIVE • " + bridgeCtrl.hashrate + " H/S") :
                          "NODE IDLE • SHA-256"
                    color: (bridgeCtrl && bridgeCtrl.isMining) ? theme.statusSuccess : theme.textMuted
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTiny
                    font.weight: (bridgeCtrl && bridgeCtrl.isMining) ? Font.Bold : Font.Normal
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Right: Tactile Segmented Pill Console
            Rectangle {
                id: actionConsole
                implicitHeight: 34
                implicitWidth: 236
                color: theme.bgInsetTrough
                radius: 8
                border.color: theme.borderSubtle
                border.width: 1

                readonly property int segmentWidth: Math.floor((actionConsole.width - 6) / 2)
                readonly property bool isDestructiveActive: (bridgeCtrl && bridgeCtrl.isMining) && bridgeCard.activeAction === "mining"

                // Drop shadow beneath active pill to produce the "timbul" physical elevation
                Rectangle {
                    x: activePill.x
                    y: activePill.y + 1
                    width: activePill.width
                    height: activePill.height
                    radius: 6
                    color: actionConsole.isDestructiveActive ? Qt.rgba(0.9, 0.1, 0.1, 0.28) : theme.btnPrimaryShadow
                    opacity: 0.9

                    Behavior on x {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }

                // Raised Active Pill
                Rectangle {
                    id: activePill
                    x: bridgeCard.activeAction === "mining" ? 3 : (3 + actionConsole.segmentWidth)
                    y: 3
                    width: actionConsole.segmentWidth
                    height: actionConsole.height - 6
                    radius: 6

                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: {
                                if (actionConsole.isDestructiveActive) {
                                    return miningMouse.pressed ? "#991B1B" : (miningMouse.containsMouse ? "#DC2626" : "#B91C1C");
                                }
                                var isPressed = (bridgeCard.activeAction === "mining" && miningMouse.pressed) ||
                                                (bridgeCard.activeAction === "bridge" && bridgeMouse.pressed);
                                var isHovered = (bridgeCard.activeAction === "mining" && miningMouse.containsMouse) ||
                                                (bridgeCard.activeAction === "bridge" && bridgeMouse.containsMouse);
                                return isPressed ? theme.btnPrimaryPressed : (isHovered ? theme.btnPrimaryHoverTop : theme.btnPrimaryTop);
                            }
                        }
                        GradientStop {
                            position: 1.0
                            color: {
                                if (actionConsole.isDestructiveActive) {
                                    return miningMouse.pressed ? "#7F1D1D" : (miningMouse.containsMouse ? "#B91C1C" : "#991B1B");
                                }
                                var isPressed = (bridgeCard.activeAction === "mining" && miningMouse.pressed) ||
                                                (bridgeCard.activeAction === "bridge" && bridgeMouse.pressed);
                                var isHovered = (bridgeCard.activeAction === "mining" && miningMouse.containsMouse) ||
                                                (bridgeCard.activeAction === "bridge" && bridgeMouse.containsMouse);
                                return isPressed ? theme.btnPrimaryPressed : (isHovered ? theme.btnPrimaryHoverBottom : theme.btnPrimaryBottom);
                            }
                        }
                    }

                    border.color: actionConsole.isDestructiveActive ? "#EF4444" : theme.btnPrimaryBorderSides
                    border.width: 1

                    // Top bevel highlight line
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 1
                        height: 1
                        color: "#FFFFFF"
                        opacity: 0.22
                        radius: 5
                    }

                    Behavior on x {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }

                // Interactive Segments
                Row {
                    anchors.fill: parent
                    anchors.margins: 3

                    // Segment 1: Mining
                    Item {
                        id: miningSegment
                        width: actionConsole.segmentWidth
                        height: parent.height

                        Text {
                            id: miningLabel
                            anchors.centerIn: parent
                            text: (bridgeCtrl && bridgeCtrl.isMining) ? "Stop Mining" : "Start Mining"
                            color: bridgeCard.activeAction === "mining" ?
                                   theme.textPrimary :
                                   (miningMouse.containsMouse ? theme.textPrimary : theme.textSecondary)
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeSmall
                            font.weight: bridgeCard.activeAction === "mining" ? Font.DemiBold : Font.Medium
                        }

                        MouseArea {
                            id: miningMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
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
                    }

                    // Segment 2: Bridge Tokens
                    Item {
                        id: bridgeSegment
                        width: actionConsole.segmentWidth
                        height: parent.height

                        readonly property bool canBridge: !bridge.isLocked &&
                                                          accountStore.activeAccount !== null &&
                                                          bridgeCtrl !== null &&
                                                          bridgeCtrl.hasUnbridgedTokens &&
                                                          !bridgeCtrl.isDepositing

                        opacity: bridgeCard.activeAction === "bridge" ? 1.0 : (bridgeSegment.canBridge ? 1.0 : 0.45)

                        Text {
                            id: bridgeLabel
                            anchors.centerIn: parent
                            text: (bridgeCtrl && bridgeCtrl.isDepositing) ? "Bridging..." : "Bridge Tokens"
                            color: bridgeCard.activeAction === "bridge" ?
                                   theme.textPrimary :
                                   (bridgeMouse.containsMouse && bridgeSegment.canBridge ? theme.textPrimary : theme.textSecondary)
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeSmall
                            font.weight: bridgeCard.activeAction === "bridge" ? Font.DemiBold : Font.Medium
                        }

                        MouseArea {
                            id: bridgeMouse
                            anchors.fill: parent
                            hoverEnabled: bridgeSegment.canBridge
                            cursorShape: bridgeSegment.canBridge ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (bridgeSegment.canBridge) {
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
    }
}
