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

    property var rawTransactions: []

    readonly property var filteredTransactions: {
        if (ledgerCard.activeFilter === "All")
            return rawTransactions;
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
        if (status === "Private" || status === "Shield")
            return theme.statusShielded;
        if (status === "Unshield")
            return theme.statusSuccess;
        if (status === "Faucet")
            return theme.accentOrange;
        if (status === "Ledger")
            return theme.accentOrange;
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
            txHash: txHash || "",
            gasUsed: gasUsed || "0.00015 LEZ",
            gasLimit: "34,000",
            block: block !== undefined ? block : "-",
            route: route || (isIncoming ? "External → Internal" : "Internal → On-Chain")
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

            Item {
                Layout.fillWidth: true
            }

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

        // Empty State Display
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignCenter
            visible: ledgerCard.filteredTransactions.length === 0
            spacing: 8

            Item {
                Layout.fillHeight: true
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "No transactions recorded yet"
                color: theme.textSecondary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeBody
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: "Incoming and outgoing on-chain transfers will appear here in real-time."
                color: theme.textMuted
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeSmall
            }

            Item {
                Layout.fillHeight: true
            }
        }

        // Activity Items List (Window of 10 items)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            visible: ledgerCard.filteredTransactions.length > 0

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
                    if (ledgerCard.currentPage > 0)
                        ledgerCard.currentPage--;
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: {
                    var total = ledgerCard.filteredTransactions.length;
                    if (total === 0)
                        return "0 items";
                    var start = ledgerCard.currentPage * ledgerCard.pageSize + 1;
                    var end = Math.min((ledgerCard.currentPage + 1) * ledgerCard.pageSize, total);
                    return start + "–" + end + " of " + total;
                }
                color: theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "›"
                isCompact: true
                customWidth: 28
                customHeight: 28
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                enabled: (ledgerCard.currentPage + 1) < ledgerCard.totalPages
                onClicked: {
                    if ((ledgerCard.currentPage + 1) < ledgerCard.totalPages)
                        ledgerCard.currentPage++;
                }
            }
        }
    }
}
