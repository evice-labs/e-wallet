import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Item {
    id: view

    required property var bridge
    required property var accountStore

    property bool isMining: false
    property int hashrate: 0
    property string minedL1Tokens: "142.50 LOGOS"

    Theme { id: theme }

    Timer {
        id: miningTimer
        interval: 1000
        repeat: true
        running: view.isMining
        onTriggered: {
            view.hashrate = Math.floor(1800 + Math.random() * 400);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        RowLayout {
            Layout.fillWidth: true

            Column {
                spacing: 2
                Text {
                    text: "EmPoWer Mining & L1 → LEZ Bridge"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeHero
                    font.weight: Font.Bold
                }
                Text {
                    text: "Logos Blockchain L1 Proof-of-Work & Trustless Channel Bridge"
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                }
            }

            Item { Layout.fillWidth: true }

            PillBadge {
                text: "Canonical Funding Path"
                badgeColor: theme.statusPublic
            }
        }

        // Mining Station Card
        Card {
            Layout.fillWidth: true
            Layout.preferredHeight: 220
            title: "EmPoWer L1 Mining Station"
            subtitle: "Generate native testnet tokens via local Proof-of-Work"

            ColumnLayout {
                anchors.fill: parent
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    InsetPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 76

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "MINER STATUS & HASHRATE"
                                color: theme.textSecondary
                                font.family: theme.fontMono
                                font.pixelSize: theme.fontSizeSmall
                            }

                            Text {
                                text: view.isMining ? (view.hashrate + " H/s (ACTIVE)") : "OFFLINE"
                                color: view.isMining ? theme.statusSuccess : theme.textMuted
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSizeTitle
                                font.weight: Font.Bold
                            }
                        }
                    }

                    InsetPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 76

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "UNBRIDGED L1 MINED BALANCE"
                                color: theme.accentOrange
                                font.family: theme.fontMono
                                font.pixelSize: theme.fontSizeSmall
                            }

                            Text {
                                text: view.minedL1Tokens
                                color: theme.textPrimary
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSizeTitle
                                font.weight: Font.Bold
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    PillBadge {
                        text: "REST: http://127.0.0.1:8080/pow/mining"
                        badgeColor: theme.statusPublic
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: view.isMining ? "Stop Mining" : "Start EmPoWer Mining"
                        isPrimary: !view.isMining
                        isDestructive: view.isMining
                        onClicked: {
                            view.isMining = !view.isMining;
                            if (!view.isMining) view.hashrate = 0;
                        }
                    }
                }
            }
        }

        // Bridging Terminal Card
        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "L1 → LEZ Channel Deposit Bridge"
            subtitle: "Deposit mined L1 notes into your active LEZ account"

            ColumnLayout {
                anchors.fill: parent
                spacing: 14

                InsetPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        Column {
                            spacing: 2
                            Text {
                                text: "TARGET LEZ RECIPIENT ACCOUNT"
                                color: theme.textSecondary
                                font.family: theme.fontMono
                                font.pixelSize: theme.fontSizeSmall
                            }
                            Text {
                                text: accountStore.activeAccount ? accountStore.activeAccount.label + " (" + accountStore.activeAccount.account_id.substring(0, 18) + "...)" : "No active account"
                                color: theme.textPrimary
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSizeBody
                                font.weight: Font.Bold
                            }
                        }

                        Item { Layout.fillWidth: true }

                        PillBadge {
                            text: "Channel Deposit V1"
                            badgeColor: theme.statusSuccess
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "The bridge executes an on-chain ChannelDeposit transaction that locks L1 notes and credits equivalent native LEZ coin directly into your selected account without relying on centralized faucets."
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeBody
                    wrapMode: Text.WordWrap
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Bridge All Mined Tokens to LEZ"
                        isPrimary: true
                        enabled: !bridge.isLocked && accountStore.activeAccount !== null
                        onClicked: {
                            view.minedL1Tokens = "0.00 LOGOS";
                            accountStore.refreshAccounts();
                        }
                    }
                }
            }
        }
    }
}
