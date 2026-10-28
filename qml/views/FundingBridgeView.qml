import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Card {
    id: faucetMiningCard

    required property var bridge
    required property var accountStore
    property var ledgerViewRef: null

    implicitHeight: 195

    property bool isMining: false
    property bool isClaiming: false
    property int hashrate: 24
    property string faucetStatus: ""
    property int blocksMined: 0
    readonly property int actionButtonWidth: Math.max(115, Math.max(claimButton.implicitWidth, miningButton.implicitWidth))

    title: "Faucet & Mining"

    headerRight: Component {
        RowLayout {
            spacing: 6

            Rectangle {
                implicitWidth: 6
                implicitHeight: 6
                radius: 3
                color: faucetMiningCard.isMining ? theme.statusSuccess : theme.textMuted
            }

            Text {
                text: faucetMiningCard.isMining ? ("NODE ACTIVE • " + faucetMiningCard.hashrate + " H/S") : "NODE IDLE"
                color: faucetMiningCard.isMining ? theme.statusSuccess : theme.textMuted
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTiny
                font.weight: Font.Bold
            }
        }
    }

    Timer {
        id: miningTimer
        interval: 1200
        repeat: true
        running: faucetMiningCard.isMining
        onTriggered: {
            faucetMiningCard.hashrate = Math.floor(22 + Math.random() * 5);
            if (Math.random() < 0.2) {
                faucetMiningCard.blocksMined += 1;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 6

        // BODY: Faucet Info & PoW Mining Telemetry
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            // Faucet Section
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "Testnet Faucet"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeBody
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: "Claim 100 LEZ liquidity for testnet transfers and smart contracts"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: faucetMiningCard.faucetStatus.length > 0
                        text: faucetMiningCard.faucetStatus
                        color: theme.accentOrange
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Button {
                    id: claimButton
                    text: faucetMiningCard.isClaiming ? "Claiming..." : "Claim 100 LEZ"
                    isCompact: true
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: faucetMiningCard.actionButtonWidth
                    enabled: !faucetMiningCard.isClaiming
                    onClicked: {
                        faucetMiningCard.isClaiming = true;
                        faucetMiningCard.faucetStatus = "Requesting faucet liquidity...";
                        var accId = accountStore.activeAccount ? accountStore.activeAccount.account_id : "";
                        bridge.invoke("requestFaucet", [accId], function(res) {
                            faucetMiningCard.isClaiming = false;
                            if (res && res.ok) {
                                faucetMiningCard.faucetStatus = "Faucet request confirmed! +100.00 LEZ credited.";
                                accountStore.refreshAccounts();
                                if (faucetMiningCard.ledgerViewRef) {
                                    faucetMiningCard.ledgerViewRef.addActivity("Faucet", "Faucet", "Transfers", "+100.00 LEZ", "Testnet Faucet Claim", true);
                                }
                            } else {
                                faucetMiningCard.faucetStatus = "Faucet claim error: " + (res && res.error ? res.error : "Unknown");
                            }
                        });
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: theme.borderSubtle
            }

            // Mining Section (Info on Left, Action Button on Right)
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: "PoW Mining & Validator"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeBody
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: faucetMiningCard.isMining ? ("RUNNING (" + faucetMiningCard.hashrate + " H/S)") : "STOPPED"
                            color: faucetMiningCard.isMining ? theme.statusSuccess : theme.textMuted
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeTiny
                            font.weight: Font.Bold
                        }

                        Text {
                            text: faucetMiningCard.isMining ? "• Validating block transactions" : "• Node consensus idle"
                            color: theme.textMuted
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeSmall
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }

                Button {
                    id: miningButton
                    text: faucetMiningCard.isMining ? "Stop Mining" : "Start Mining"
                    isCompact: true
                    isPrimary: !faucetMiningCard.isMining
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: faucetMiningCard.actionButtonWidth
                    onClicked: {
                        faucetMiningCard.isMining = !faucetMiningCard.isMining;
                    }
                }
            }
        }

        // FLEXIBLE EXPANDING SPACER (absorbs vertical stretch)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // STATIC FOOTER: Node Consensus & Faucet Quota Telemetry
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: faucetMiningCard.width >= 480 ? "Faucet Quota: 100 LEZ / 24h • Cooldown: Ready" : "Quota: 100 LEZ / 24h"
                color: theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: {
                    if (faucetMiningCard.isMining) {
                        return faucetMiningCard.width >= 480 ? ("PoW Active • Mined: " + faucetMiningCard.blocksMined + " Blocks") : ("Mined: " + faucetMiningCard.blocksMined + " Blk");
                    }
                    return faucetMiningCard.width >= 480 ? "Consensus: SHA-256 PoW (Testnet)" : "SHA-256 PoW";
                }
                color: faucetMiningCard.isMining ? theme.statusSuccess : theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
                Layout.alignment: Qt.AlignRight
                elide: Text.ElideRight
            }
        }
    }
}
