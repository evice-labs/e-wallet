import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Card {
    id: faucetMiningCard

    required property var bridge
    required property var accountStore

    property bool isMining: false
    property int hashrate: 24
    property string faucetStatus: ""

    title: "FAUCET & MINING"
    subtitle: "Testnet Liquidity & PoW Validator Node"

    Timer {
        id: miningTimer
        interval: 1200
        repeat: true
        running: faucetMiningCard.isMining
        onTriggered: {
            faucetMiningCard.hashrate = Math.floor(22 + Math.random() * 5);
        }
    }

    ColumnLayout {
        width: parent.width
        spacing: 14

        // Faucet Section
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Column {
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
                    text: "Claim 100 LEZ for testnet experimentation"
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                }
            }

            Button {
                text: "Claim 100 LEZ"
                isCompact: true
                onClicked: {
                    faucetMiningCard.faucetStatus = "Faucet request submitted! +100.00 LEZ received.";
                    bridge.invoke("requestFaucet", [accountStore.activeAccount ? accountStore.activeAccount.address : ""]);
                }
            }
        }

        Text {
            visible: faucetMiningCard.faucetStatus.length > 0
            text: faucetMiningCard.faucetStatus
            color: theme.accentOrange
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
        }

        // Skeuomorphic Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: theme.borderSubtle
        }

        // Mining Section
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Column {
                Layout.fillWidth: true
                spacing: 4
                Text {
                    text: "PoW Mining / Validator Node"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeBody
                    font.weight: Font.DemiBold
                }
                Row {
                    spacing: 6
                    PillBadge {
                        text: faucetMiningCard.isMining ? "Running (" + faucetMiningCard.hashrate + " H/s)" : "Stopped"
                        badgeColor: faucetMiningCard.isMining ? theme.statusSuccess : theme.textMuted
                    }
                    Text {
                        text: faucetMiningCard.isMining ? "Validating blocks" : "Node idle"
                        color: theme.textMuted
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            Button {
                text: faucetMiningCard.isMining ? "Stop Mining" : "Start Mining"
                isCompact: true
                isPrimary: !faucetMiningCard.isMining
                onClicked: {
                    faucetMiningCard.isMining = !faucetMiningCard.isMining;
                }
            }
        }
    }
}
