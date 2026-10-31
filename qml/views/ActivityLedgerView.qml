import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Card {
    id: ledgerCard

    required property var bridge
    required property var accountStore

    implicitHeight: 520

    signal openTxDetailModal(var txData)

    property string activeFilter: "All" // "All" | "Transfers" | "Shields" | "Testimonials"
    property int currentPage: 0
    readonly property int pageSize: 7

    property var rawTransactions: [
        {
            name: "bob.lez",
            status: "Public",
            category: "Transfers",
            time: "2 mins ago",
            detailedTime: "2026-10-30 17:45:10 UTC (2 mins ago)",
            amount: "-10.00 LEZ",
            detail: "Public Transfer",
            isIncoming: false,
            txHash: "0x8f3c2b1a9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b3a210987654321fedcba0987",
            gasUsed: "34,000 units (0.00015 LEZ)",
            gasLimit: "34,000",
            block: 43572,
            route: "Public ➝ Public"
        },
        {
            name: "Mining Station",
            status: "Faucet",
            category: "Transfers",
            time: "1 hour ago",
            detailedTime: "2026-10-30 16:47:00 UTC (1 hour ago)",
            amount: "+100.00 LEZ",
            detail: "L1 → LEZ Channel Deposit",
            isIncoming: true,
            txHash: "0x3f9e8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f",
            gasUsed: "Deposit (L1 Bridge)",
            gasLimit: "34,000",
            block: 43568,
            route: "Logos L1 ➝ LEZ"
        },
        {
            name: "judit.lez",
            status: "Shield",
            category: "Shields",
            time: "Yesterday",
            detailedTime: "2026-10-29 18:20:12 UTC (Yesterday)",
            amount: "-25.00 LEZ",
            detail: "Shield Asset to Private Pool",
            isIncoming: false,
            txHash: "0x6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f6a5b",
            gasUsed: "34,000 units (0.00015 LEZ)",
            gasLimit: "34,000",
            block: 43566,
            route: "Public ➝ Shield"
        },
        {
            name: "Testimonial",
            status: "Ledger",
            category: "Testimonials",
            time: "2 days ago",
            detailedTime: "2026-10-28 14:10:45 UTC (2 days ago)",
            amount: "\"Hello Logos\"",
            detail: "On-Chain zkVM Broadcast",
            isIncoming: false,
            txHash: "0xb2655903cac86b50b55d0a8c0feb062dd2113ebe5292423d23ab8924f8189bfc",
            gasUsed: "34,000 units (0.00015 LEZ)",
            gasLimit: "34,000",
            block: 43565,
            route: "Public ➝ zkVM Contract"
        },
        {
            name: "bob.lez",
            status: "Unshield",
            category: "Shields",
            time: "3 days ago",
            detailedTime: "2026-10-27 09:30:00 UTC (3 days ago)",
            amount: "+15.00 LEZ",
            detail: "Unshield Asset to Public Pool",
            isIncoming: true,
            txHash: "0x5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e",
            gasUsed: "34,000 units (0.00015 LEZ)",
            gasLimit: "34,000",
            block: 43562,
            route: "Shield ➝ Public"
        },
        {
            name: "jef.lez",
            status: "Private",
            category: "Transfers",
            time: "4 days ago",
            detailedTime: "2026-10-26 15:15:20 UTC (4 days ago)",
            amount: "-5.00 LEZ",
            detail: "Zero-Knowledge Transfer",
            isIncoming: false,
            txHash: "0x4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f",
            gasUsed: "34,000 units (0.00015 LEZ)",
            gasLimit: "34,000",
            block: 43558,
            route: "Shield ➝ Shield"
        },
        {
            name: "Mining Station",
            status: "Faucet",
            category: "Transfers",
            time: "5 days ago",
            detailedTime: "2026-10-25 11:00:15 UTC (5 days ago)",
            amount: "+142.50 LEZ",
            detail: "L1 → LEZ Channel Deposit",
            isIncoming: true,
            txHash: "0x7c9a1b2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b",
            gasUsed: "Deposit (L1 Bridge)",
            gasLimit: "34,000",
            block: 43552,
            route: "Logos L1 ➝ LEZ"
        },
        {
            name: "Testimonial",
            status: "Ledger",
            category: "Testimonials",
            time: "6 days ago",
            detailedTime: "2026-10-24 16:40:50 UTC (6 days ago)",
            amount: "\"Decentralized zkVM\"",
            detail: "On-Chain zkVM Broadcast",
            isIncoming: false,
            txHash: "0x2b9611089ea143068fddc4f8423e5c0b501c039e89daf46df89913ae1885205c",
            gasUsed: "34,000 units (0.00015 LEZ)",
            gasLimit: "34,000",
            block: 43458,
            route: "Public ➝ zkVM Contract"
        },
        {
            name: "alice.lez",
            status: "Shield",
            category: "Shields",
            time: "1 week ago",
            detailedTime: "2026-10-23 12:10:30 UTC (1 week ago)",
            amount: "+50.00 LEZ",
            detail: "ZK Note Deposit",
            isIncoming: true,
            txHash: "0xf0ab6e73fd4971e7d84482a5a7ba500dea4c68d16a75604c11ccf927117c1d26",
            gasUsed: "34,000 units (0.00015 LEZ)",
            gasLimit: "34,000",
            block: 43462,
            route: "Public ➝ Shield"
        },
        {
            name: "charlie.lez",
            status: "Public",
            category: "Transfers",
            time: "1 week ago",
            detailedTime: "2026-10-23 08:05:12 UTC (1 week ago)",
            amount: "-12.00 LEZ",
            detail: "Public Transfer",
            isIncoming: false,
            txHash: "0x284df1263bfc0db924c3c27b9bf6d4bd35a2a548073e61d86db7207cb29fd8d7",
            gasUsed: "34,000 units (0.00015 LEZ)",
            gasLimit: "34,000",
            block: 43465,
            route: "Public ➝ Public"
        },
        {
            name: "dave.lez",
            status: "Public",
            category: "Transfers",
            time: "2 weeks ago",
            detailedTime: "2026-10-16 14:22:18 UTC (2 weeks ago)",
            amount: "-8.50 LEZ",
            detail: "Public Transfer",
            isIncoming: false,
            txHash: "0x0fdbea883f8e2236841892b368d338e95ad6750431079dd633f54680b17813dd",
            gasUsed: "34,000 units (0.00015 LEZ)",
            gasLimit: "34,000",
            block: 43457,
            route: "Public ➝ Public"
        },
        {
            name: "Testimonial",
            status: "Ledger",
            category: "Testimonials",
            time: "2 weeks ago",
            detailedTime: "2026-10-16 10:11:05 UTC (2 weeks ago)",
            amount: "\"Privacy is Normal\"",
            detail: "On-Chain zkVM Broadcast",
            isIncoming: false,
            txHash: "0x9f538361b55c890f9bd5dae00cf98d4bb677cc3bd129c0147fbe4b23fccaf184",
            gasUsed: "34,000 units (0.00015 LEZ)",
            gasLimit: "34,000",
            block: 43466,
            route: "Public ➝ zkVM Contract"
        },
        {
            name: "Mining Station",
            status: "Faucet",
            category: "Transfers",
            time: "3 weeks ago",
            detailedTime: "2026-10-09 17:30:40 UTC (3 weeks ago)",
            amount: "+210.00 LEZ",
            detail: "L1 → LEZ Channel Deposit",
            isIncoming: true,
            txHash: "0x1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b",
            gasUsed: "Deposit (L1 Bridge)",
            gasLimit: "34,000",
            block: 43420,
            route: "Logos L1 ➝ LEZ"
        },
        {
            name: "eve.lez",
            status: "Shield",
            category: "Shields",
            time: "1 month ago",
            detailedTime: "2026-09-30 13:45:22 UTC (1 month ago)",
            amount: "+75.00 LEZ",
            detail: "Shield Asset to Private Pool",
            isIncoming: true,
            txHash: "0x8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f8a7b6c5d4e3f2a1b0c9d8e7f",
            gasUsed: "34,000 units (0.00015 LEZ)",
            gasLimit: "34,000",
            block: 43380,
            route: "Public ➝ Shield"
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

    readonly property int totalPages: Math.max(1, Math.ceil(filteredTransactions.length / pageSize))

    readonly property var windowedTransactions: {
        var start = currentPage * pageSize;
        var end = Math.min(start + pageSize, filteredTransactions.length);
        var result = [];
        for (var i = start; i < end; i++) {
            result.push(filteredTransactions[i]);
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

    function addActivity(name, status, category, amount, detail, isIncoming, txHash, gasUsed, block, route) {
        var now = new Date();
        var yyyy = now.getUTCFullYear();
        var mm = String(now.getUTCMonth() + 1).padStart(2, '0');
        var dd = String(now.getUTCDate()).padStart(2, '0');
        var hh = String(now.getUTCHours()).padStart(2, '0');
        var min = String(now.getUTCMinutes()).padStart(2, '0');
        var ss = String(now.getUTCSeconds()).padStart(2, '0');
        var nowDetailed = yyyy + "-" + mm + "-" + dd + " " + hh + ":" + min + ":" + ss + " UTC (Just now)";

        var item = {
            name: name || "Transaction",
            status: status || "Public",
            category: category || "Transfers",
            time: "Just now",
            detailedTime: nowDetailed,
            amount: amount || "0.00 LEZ",
            detail: detail || "On-Chain Activity",
            isIncoming: !!isIncoming,
            txHash: txHash || ("0x" + Math.random().toString(16).substring(2, 10) + "...c6d"),
            gasUsed: gasUsed || "34,200 units (0.00015 LEZ)",
            gasLimit: "34,000",
            block: block || 43575,
            route: route || (isIncoming ? "External → Internal" : "Internal → Testnet 0.4")
        };
        var list = [item];
        for (var i = 0; i < rawTransactions.length; i++) {
            list.push(rawTransactions[i]);
        }
        rawTransactions = list;
        currentPage = 0;
    }

    title: "Activity Feed & Transaction Ledger"

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // BODY: Filter Tabs & Transaction Items List

        // Segmented Filter Tabs & Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            SegmentedBar {
                TabButton {
                    text: "All"
                    isActive: ledgerCard.activeFilter === "All"
                    onClicked: {
                        ledgerCard.activeFilter = "All";
                        ledgerCard.currentPage = 0;
                    }
                }
                TabButton {
                    text: "Transfers"
                    isActive: ledgerCard.activeFilter === "Transfers"
                    onClicked: {
                        ledgerCard.activeFilter = "Transfers";
                        ledgerCard.currentPage = 0;
                    }
                }
                TabButton {
                    text: "Shields"
                    isActive: ledgerCard.activeFilter === "Shields"
                    onClicked: {
                        ledgerCard.activeFilter = "Shields";
                        ledgerCard.currentPage = 0;
                    }
                }
                TabButton {
                    text: "Testimonials"
                    isActive: ledgerCard.activeFilter === "Testimonials"
                    onClicked: {
                        ledgerCard.activeFilter = "Testimonials";
                        ledgerCard.currentPage = 0;
                    }
                }
            }

            Item { Layout.fillWidth: true }

            // Refresh History Action Button (Pure White Icon, 34x34)
            Button {
                iconSource: "../assets/icons/Refresh.png"
                isCompact: true
                customWidth: 34
                customHeight: 34
                Layout.alignment: Qt.AlignVCenter
                onClicked: {
                    bridge.invoke("fetchHistory", []);
                }
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // Activity Items List (Window of 10 items)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: ledgerCard.windowedTransactions
                delegate: ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Rectangle {
                        visible: index > 0
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: theme.borderSubtle
                    }

                    Rectangle {
                        id: rowContainer
                        Layout.fillWidth: true
                        height: 40
                        radius: theme.radiusButton
                        color: rowHover.containsMouse ? theme.bgSurfaceSubtle : "transparent"

                        MouseArea {
                            id: rowHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                ledgerCard.openTxDetailModal(modelData);
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 10

                            // Left: Name, Status Typography (No PillBadge), Time
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    spacing: 8
                                    Text {
                                        text: modelData.name
                                        color: theme.textPrimary
                                        font.family: theme.fontFamily
                                        font.pixelSize: theme.fontSizeSmall
                                        font.weight: Font.Bold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: modelData.status.toUpperCase()
                                        color: ledgerCard.statusColor(modelData.status)
                                        font.family: theme.fontFamily
                                        font.pixelSize: theme.fontSizeTiny
                                        font.weight: Font.Bold
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.time + " • " + modelData.detail
                                    color: theme.textMuted
                                    font.family: theme.fontMono
                                    font.pixelSize: theme.fontSizeTiny
                                    elide: Text.ElideRight
                                }
                            }

                            // Right: Formatted Amount
                            Text {
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                text: modelData.amount
                                color: modelData.isIncoming ? theme.statusSuccess : theme.textPrimary
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSizeSmall
                                font.weight: Font.Bold
                            }
                        }
                    }
                }
            }
        }

        // FLEXIBLE EXPANDING SPACER (absorbs vertical stretch)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // STATIC FOOTER: Windowing Pagination Controls
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // Windowing Pagination Controls
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Button {
                text: "‹"
                isCompact: true
                customWidth: 28
                customHeight: 28
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                enabled: ledgerCard.currentPage > 0
                onClicked: {
                    if (ledgerCard.currentPage > 0) ledgerCard.currentPage--;
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: {
                    var total = ledgerCard.filteredTransactions.length;
                    if (total === 0) return "0 items";
                    var start = ledgerCard.currentPage * ledgerCard.pageSize + 1;
                    var end = Math.min((ledgerCard.currentPage + 1) * ledgerCard.pageSize, total);
                    return start + "–" + end + " of " + total;
                }
                color: theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "›"
                isCompact: true
                customWidth: 28
                customHeight: 28
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                enabled: (ledgerCard.currentPage + 1) < ledgerCard.totalPages
                onClicked: {
                    if ((ledgerCard.currentPage + 1) < ledgerCard.totalPages) ledgerCard.currentPage++;
                }
            }
        }
    }
}
