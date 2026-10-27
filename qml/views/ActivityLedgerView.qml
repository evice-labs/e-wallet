import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Card {
    id: ledgerCard

    required property var bridge
    required property var accountStore

    property string activeFilter: "All" // "All" | "Transfers" | "Shields" | "Testimonials"

    property var rawTransactions: [
        {
            name: "bob.lez",
            status: "Public",
            category: "Transfers",
            time: "2 mins ago",
            amount: "-10.00 LEZ",
            detail: "Public Transfer",
            isIncoming: false
        },
        {
            name: "Faucet",
            status: "Faucet",
            category: "Transfers",
            time: "1 hour ago",
            amount: "+100.00 LEZ",
            detail: "Testnet Faucet Claim",
            isIncoming: true
        },
        {
            name: "james.lez",
            status: "Shield",
            category: "Shields",
            time: "Yesterday",
            amount: "-25.00 LEZ",
            detail: "Shield Asset to Private Pool",
            isIncoming: false
        },
        {
            name: "Testimonial",
            status: "Ledger",
            category: "Testimonials",
            time: "2 days ago",
            amount: "\"Hello Logos\"",
            detail: "On-Chain Broadcast (0.1 LEZ)",
            isIncoming: true
        },
        {
            name: "bob.lez",
            status: "Unshield",
            category: "Shields",
            time: "3 days ago",
            amount: "+15.00 LEZ",
            detail: "Unshield Asset to Public Pool",
            isIncoming: true
        },
        {
            name: "jef.lez",
            status: "Private",
            category: "Transfers",
            time: "4 days ago",
            amount: "-5.00 LEZ",
            detail: "Zero-Knowledge Transfer",
            isIncoming: false
        }
    ]

    readonly property var filteredTransactions: {
        if (ledgerCard.activeFilter === "All") return rawTransactions;
        var result = [];
        for (var i = 0; i < rawTransactions.length; i++) {
            if (rawTransactions[i].category === ledgerCard.activeFilter) {
                result.push(rawTransactions[i]);
            }
        }
        return result;
    }

    function statusColor(status) {
        if (status === "Private" || status === "Shield") return theme.statusShielded;
        if (status === "Unshield") return theme.statusSuccess;
        if (status === "Faucet") return theme.accentOrange;
        if (status === "Ledger") return theme.accentOrange;
        return theme.statusPublic;
    }

    title: "ACTIVITY FEED & TRANSACTION LEDGER"
    subtitle: "Real-time On-Chain Ledger & Privacy State Machine"

    ColumnLayout {
        width: parent.width
        spacing: 14

        // Filter Bar & Refresh Button
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Segmented Filter Tabs
            Row {
                spacing: 6
                TabButton {
                    text: "All"
                    isActive: ledgerCard.activeFilter === "All"
                    onClicked: ledgerCard.activeFilter = "All"
                }
                TabButton {
                    text: "Transfers"
                    isActive: ledgerCard.activeFilter === "Transfers"
                    onClicked: ledgerCard.activeFilter = "Transfers"
                }
                TabButton {
                    text: "Shields"
                    isActive: ledgerCard.activeFilter === "Shields"
                    onClicked: ledgerCard.activeFilter = "Shields"
                }
                TabButton {
                    text: "Testimonials"
                    isActive: ledgerCard.activeFilter === "Testimonials"
                    onClicked: ledgerCard.activeFilter = "Testimonials"
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Refresh"
                isCompact: true
                onClicked: {
                    bridge.invoke("fetchHistory", []);
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: theme.borderSubtle
        }

        // Activity Items List
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: ledgerCard.filteredTransactions
                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Rectangle {
                        visible: index > 0
                        Layout.fillWidth: true
                        height: 1
                        color: theme.borderSubtle
                    }

                    Item {
                        Layout.fillWidth: true
                        height: 56

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 4
                            anchors.rightMargin: 4
                            spacing: 12

                            // Left: Name, Badge, Time
                            Column {
                                spacing: 4
                                Row {
                                    spacing: 8
                                    Text {
                                        text: modelData.name
                                        color: theme.textPrimary
                                        font.family: theme.fontFamily
                                        font.pixelSize: theme.fontSizeBody
                                        font.weight: Font.Bold
                                    }

                                    PillBadge {
                                        text: modelData.status
                                        badgeColor: ledgerCard.statusColor(modelData.status)
                                    }
                                }

                                Text {
                                    text: modelData.time + " • " + modelData.detail
                                    color: theme.textMuted
                                    font.family: theme.fontMono
                                    font.pixelSize: theme.fontSizeSmall
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Right: Amount
                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: modelData.amount
                                color: modelData.isIncoming ? theme.statusSuccess : theme.textPrimary
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSizeBody
                                font.weight: Font.Bold
                            }
                        }
                    }
                }
            }
        }
    }
}
