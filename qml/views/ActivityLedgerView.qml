import QtQuick
import QtQuick.Layouts
import QtCore
import "../theme"
import "../controls"
import "../state"

Card {
    id: ledgerCard

    required property var bridge
    required property var accountStore

    GasCalculator {
        id: gasCalc
    }

    implicitHeight: 520

    signal openTxDetailModal(var txData)

    Settings {
        id: ledgerSettings
        category: "LogosEWalletActivityLedger"
        property string rawTransactionsJson: "[]"
    }

    property string activeFilter: "All" // "All" | "Transfers" | "Shields" | "Testimonials"
    property int currentPage: 0
    readonly property int pageSize: 7

    property var rawTransactions: {
        try {
            return JSON.parse(ledgerSettings.rawTransactionsJson) || [];
        } catch (e) {
            return [];
        }
    }

    Connections {
        target: accountStore
        function onActiveAccountChanged() {
            ledgerCard.currentPage = 0;
        }
    }

    readonly property var filteredTransactions: {
        var activeId = (accountStore.activeAccount && accountStore.activeAccount.account_id) ? accountStore.activeAccount.account_id : "";
        var result = [];
        for (var i = 0; i < rawTransactions.length; i++) {
            var tx = rawTransactions[i];
            if (activeId.length > 0) {
                if (tx.accountId) {
                    if (tx.accountId !== activeId)
                        continue;
                } else if (tx.route && tx.route.indexOf(activeId.substring(0, 8)) !== -1)
                // Match legacy deposit route referencing this account ID prefix
                {} else {
                    continue;
                }
            }
            if (ledgerCard.activeFilter === "All" || tx.category === ledgerCard.activeFilter) {
                result.push(tx);
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

    property int clockTick: 0

    Timer {
        id: relativeTimeTimer
        interval: 30000
        running: true
        repeat: true
        onTriggered: ledgerCard.clockTick++
    }

    function formatRelativeTime(item) {
        var _ = ledgerCard.clockTick;
        if (!item)
            return "Just now";

        var ts = Number(item.timestamp);
        if (!ts || isNaN(ts)) {
            if (item.detailedTime) {
                var dStr = String(item.detailedTime).replace(" UTC", "Z").replace(" (Just now)", "");
                var parsed = Date.parse(dStr);
                if (!isNaN(parsed)) {
                    ts = parsed;
                }
            }
        }
        if (!ts || isNaN(ts))
            return item.time || "Just now";

        var diffMs = Date.now() - ts;
        if (diffMs < 0)
            return "Just now";
        var diffSec = Math.floor(diffMs / 1000);
        if (diffSec < 60)
            return "Just now";
        var diffMin = Math.floor(diffSec / 60);
        if (diffMin < 60)
            return diffMin + " min" + (diffMin === 1 ? "" : "s") + " ago";
        var diffHr = Math.floor(diffMin / 60);
        if (diffHr < 24)
            return diffHr + " hour" + (diffHr === 1 ? "" : "s") + " ago";
        var diffDays = Math.floor(diffHr / 24);
        if (diffDays < 7)
            return diffDays + " day" + (diffDays === 1 ? "" : "s") + " ago";
        return new Date(ts).toLocaleDateString();
    }

    function statusColor(status) {
        if (status === "Private" || status === "Shield")
            return theme.statusShielded;
        if (status === "Unshield" || status === "Deposit")
            return theme.statusSuccess;
        if (status === "Faucet")
            return theme.accentOrange;
        if (status === "Ledger")
            return theme.accentOrange;
        return theme.statusPublic;
    }

    function formatActivityAmount(amountStr) {
        if (!amountStr || !accountStore)
            return "0";
        var s = String(amountStr).replace(/\s*LEZ\b/gi, "").trim();
        var m = s.match(/^([+-]?)([0-9,]+(?:\.[0-9]+)?)(?:\s+(.+))?$/);
        if (!m)
            return s;
        var sign = m[1] || "";
        var rawNum = m[2].replace(/,/g, "");
        var tokenSymbol = m[3] ? (" " + m[3]) : "";
        return sign + accountStore.formatThousands(rawNum) + tokenSymbol;
    }

    function addActivity(name, status, category, amount, detail, isIncoming, txHash, gasUsed, block, route, targetAccountId, gasLimit) {
        var formattedAmount = formatActivityAmount(amount || "0");
        var now = new Date();
        var yyyy = now.getUTCFullYear();
        var mm = String(now.getUTCMonth() + 1).padStart(2, '0');
        var dd = String(now.getUTCDate()).padStart(2, '0');
        var hh = String(now.getUTCHours()).padStart(2, '0');
        var min = String(now.getUTCMinutes()).padStart(2, '0');
        var ss = String(now.getUTCSeconds()).padStart(2, '0');
        var nowDetailed = yyyy + "-" + mm + "-" + dd + " " + hh + ":" + min + ":" + ss + " UTC";

        var activeId = targetAccountId || ((accountStore.activeAccount && accountStore.activeAccount.account_id) ? accountStore.activeAccount.account_id : "");

        // Deduplication for auto-detected deposits if already recorded by an intra-wallet transfer
        if (isIncoming && (!txHash || txHash === "" || txHash === "External Inbound (Sequencer State Sync)")) {
            for (var d = 0; d < rawTransactions.length; d++) {
                var prevTx = rawTransactions[d];
                if (prevTx.accountId === activeId && prevTx.isIncoming && formatActivityAmount(prevTx.amount) === formattedAmount) {
                    var elapsed = Math.abs(now.getTime() - (prevTx.timestamp || 0));
                    if (elapsed < 90000) {
                        return;
                    }
                }
            }
        }

        var defaultGasUsed = isIncoming ? "0 (Paid by Sender)" : gasCalc.formatGasResult(gasCalc.gasPublicNative, gasCalc.storPublicNative, gasCalc.limitStandard).displayStr;
        var defaultGasLimit = isIncoming ? "0" : "34,000";

        var item = {
            name: name || "Transaction",
            status: status || "Public",
            category: category || "Transfers",
            timestamp: now.getTime(),
            time: "Just now",
            detailedTime: nowDetailed,
            amount: formattedAmount,
            detail: detail || "On-Chain Activity",
            isIncoming: !!isIncoming,
            txHash: txHash || (isIncoming ? "External Inbound (Sequencer State Sync)" : "-"),
            gasUsed: gasCalc.normalizeDisplay(gasUsed || defaultGasUsed, !!isIncoming, category, status, detail),
            gasLimit: (gasLimit && String(gasLimit).length > 0) ? String(gasLimit).replace(/\s*units\b/gi, "").trim() : defaultGasLimit,
            block: (block !== undefined && block !== null && block !== "") ? block : "-",
            route: route || (isIncoming ? "External → Internal" : "Internal → On-Chain"),
            accountId: activeId
        };
        var list = [item];
        for (var i = 0; i < rawTransactions.length; i++) {
            list.push(rawTransactions[i]);
        }
        if (list.length > 50) {
            list = list.slice(0, 50);
        }
        rawTransactions = list;
        try {
            ledgerSettings.rawTransactionsJson = JSON.stringify(list);
        } catch (e) {
            console.warn("[ActivityLedger] Failed to save transactions to Settings:", e);
        }
        currentPage = 0;
    }

    function markAccountPendingTransactionsConfirmed(accId, confirmedBlock) {
        if (!accId)
            return;
        var cleanAccId = accId.replace(/^public\//i, "").replace(/^private\//i, "");
        var found = false;
        var updated = [];
        for (var i = 0; i < rawTransactions.length; i++) {
            var item = Object.assign({}, rawTransactions[i]);
            var itemAccId = (item.accountId || "").replace(/^public\//i, "").replace(/^private\//i, "");
            var isPending = (item.block === "Pending" || item.block === "Pending Block" || item.isPending === true);
            if (isPending && (itemAccId === cleanAccId || itemAccId === "")) {
                item.block = (confirmedBlock !== undefined && confirmedBlock !== null && confirmedBlock !== "") ? confirmedBlock : "Sequencer Confirmed";
                item.isPending = false;
                found = true;
            }
            updated.push(item);
        }
        if (found) {
            rawTransactions = updated;
            try {
                ledgerSettings.rawTransactionsJson = JSON.stringify(updated);
            } catch (e) {
                console.warn("[ActivityLedger] Failed to save updated transactions to Settings:", e);
            }
        }
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
                    if (accountStore) {
                        accountStore.refreshAccounts();
                        accountStore.refreshTokens();
                    }
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
                                var txCopy = Object.assign({}, modelData);
                                txCopy.amount = ledgerCard.formatActivityAmount(modelData.amount);
                                ledgerCard.openTxDetailModal(txCopy);
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
                                        text: (modelData.status || "").toUpperCase()
                                        color: ledgerCard.statusColor(modelData.status)
                                        font.family: theme.fontFamily
                                        font.pixelSize: theme.fontSizeTiny
                                        font.weight: Font.Bold
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: ledgerCard.formatRelativeTime(modelData) + " • " + modelData.detail
                                    color: theme.textMuted
                                    font.family: theme.fontMono
                                    font.pixelSize: theme.fontSizeTiny
                                    elide: Text.ElideRight
                                }
                            }

                            // Right: Formatted Amount
                            Text {
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                text: ledgerCard.formatActivityAmount(modelData.amount)
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
