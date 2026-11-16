import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"
import "../state"

ModalOverlay {
    id: modal

    title: "Transaction Details"
    dialogWidth: 500
    dialogHeight: detailCol ? Math.max(460, Math.round(detailCol.implicitHeight + 109)) : 520

    property var txData: null
    property var accountStore: null
    property string copyStatus: ""

    function inspect(data) {
        txData = data;
        open();
    }

    function markConfirmed() {
        if (visible && txData) {
            var m = Object.assign({}, txData);
            if (!m.block || !String(m.block).startsWith("Block #")) {
                m.block = "Block #...";
            }
            m.isPending = false;
            txData = m;
        }
    }

    function updateStatus(txHash, block, isPending, isFailed) {
        if (visible && txData && txData.txHash && txHash && String(txData.txHash).trim().toLowerCase() === String(txHash).trim().toLowerCase()) {
            var m = Object.assign({}, txData);
            m.block = block;
            m.isPending = isPending;
            m.isFailed = isFailed;
            txData = m;
        }
    }

    function getStatusText() {
        if (!txData)
            return "PUBLIC";
        var bStr = String(txData.block || "");
        if (bStr.indexOf("Drop") !== -1 || bStr.indexOf("Failed") !== -1 || txData.isFailed === true) {
            return "DROP FROM MEMPOOL";
        }
        if (txData.isPending === true || bStr === "Pending" || bStr === "Pending Block" || bStr === "Sequencer Pending") {
            return "PENDING";
        }
        return (txData.status || "PUBLIC").toUpperCase();
    }

    function getStatusColor() {
        if (!txData)
            return theme.statusPublic;
        var bStr = String(txData.block || "");
        if (bStr.indexOf("Drop") !== -1 || bStr.indexOf("Failed") !== -1 || txData.isFailed === true) {
            return theme.statusDanger;
        }
        if (txData.isPending === true || bStr === "Pending" || bStr === "Pending Block" || bStr === "Sequencer Pending") {
            return theme.accentOrange;
        }
        var st = txData.status;
        if (st === "Pending")
            return theme.accentOrange;
        if (st === "Channel Bridge")
            return theme.accentDarkYellow;
        if (st === "DAPP" || st === "dApp")
            return theme.statusShielded;
        if (st === "Private" || st === "Shield")
            return theme.statusShielded;
        if (st === "Unshield" || st === "Deposit")
            return theme.statusSuccess;
        if (st === "Faucet" || st === "Ledger")
            return theme.accentOrange;
        return theme.statusPublic;
    }

    function getCleanRoute() {
        if (!txData)
            return "Public ➝ Public";
        var r = String(txData.route || "");
        var sep = "";
        if (r.indexOf("➝") !== -1)
            sep = "➝";
        else if (r.indexOf("→") !== -1)
            sep = "→";
        else if (r.indexOf("->") !== -1)
            sep = "->";

        if (sep) {
            var parts = r.split(sep);
            var fromPart = parts[0].trim();
            var toPart = parts[1].trim();

            var cleanFrom = "Public";
            if (/private|shield/i.test(fromPart))
                cleanFrom = "Private";
            else if (/logos\s*l1|l1/i.test(fromPart))
                cleanFrom = "Logos L1";
            else if (/external/i.test(fromPart))
                cleanFrom = "External";
            else if (/public/i.test(fromPart))
                cleanFrom = "Public";

            var cleanTo = "Public";
            if (/zkvm/i.test(toPart))
                cleanTo = "zkVM Contract";
            else if (/channel/i.test(toPart))
                cleanTo = "LEZ Channel";
            else if (/private|shield/i.test(toPart))
                cleanTo = "Private";
            else if (/public/i.test(toPart))
                cleanTo = "Public";
            else if (/internal/i.test(toPart))
                cleanTo = "Internal";
            else if (/on-chain/i.test(toPart))
                cleanTo = "On-Chain";

            return cleanFrom + " ➝ " + cleanTo;
        }

        var st = (txData.status || "").toLowerCase();
        if (st === "channel bridge")
            return "Logos L1 ➝ LEZ Channel";
        if (st === "shield")
            return "Public ➝ Private";
        if (st === "unshield")
            return "Private ➝ Public";
        if (st === "private")
            return "Private ➝ Private";
        if (st === "ledger" || st === "dapp" || txData.category === "Testimonials" || txData.category === "dApps")
            return "Public ➝ zkVM Contract";
        if (txData.isIncoming)
            return "External ➝ Public";
        return "Public ➝ Public";
    }

    function formatRelativeAgo(diffMs) {
        if (diffMs < 0)
            return "Just now";
        var diffSec = Math.floor(diffMs / 1000);
        if (diffSec < 10)
            return "Just now";
        if (diffSec < 60)
            return diffSec + " sec" + (diffSec === 1 ? "" : "s") + " ago";
        var diffMin = Math.floor(diffSec / 60);
        if (diffMin < 60)
            return diffMin + " min" + (diffMin === 1 ? "" : "s") + " ago";
        var diffHr = Math.floor(diffMin / 60);
        if (diffHr < 24)
            return diffHr + " hour" + (diffHr === 1 ? "" : "s") + " ago";
        var diffDays = Math.floor(diffHr / 24);
        if (diffDays < 7)
            return diffDays + " day" + (diffDays === 1 ? "" : "s") + " ago";
        var diffWeeks = Math.floor(diffDays / 7);
        if (diffDays < 30)
            return diffWeeks + " week" + (diffWeeks === 1 ? "" : "s") + " ago";
        var diffMonths = Math.floor(diffDays / 30);
        if (diffMonths < 12)
            return diffMonths + " month" + (diffMonths === 1 ? "" : "s") + " ago";
        var diffYears = Math.floor(diffDays / 365);
        return diffYears + " year" + (diffYears === 1 ? "" : "s") + " ago";
    }

    function resolveFullAddress(addrStr) {
        if (!addrStr || addrStr === "-" || addrStr === "External Sender" || addrStr === "Active Account" || addrStr === "Destination Address" || addrStr === "LEZ Channel" || addrStr === "Logos L1" || addrStr === "zkVM Contract") {
            return addrStr || "-";
        }
        var clean = String(addrStr).trim();
        if (clean.toLowerCase().startsWith("public/"))
            clean = clean.substring(7).trim();
        else if (clean.toLowerCase().startsWith("private/"))
            clean = clean.substring(8).trim();

        if (clean.indexOf("...") !== -1 && accountStore) {
            var prefixPart = clean.split("...")[0].trim();
            if (prefixPart.length >= 4) {
                if (accountStore.activeAccount && accountStore.activeAccount.account_id) {
                    var actId = String(accountStore.activeAccount.account_id);
                    if (actId.indexOf(prefixPart) === 0) {
                        return actId;
                    }
                }
                if (Array.isArray(accountStore.accounts)) {
                    for (var i = 0; i < accountStore.accounts.length; i++) {
                        var accId = String(accountStore.accounts[i].account_id || "");
                        if (accId && accId.indexOf(prefixPart) === 0) {
                            return accId;
                        }
                    }
                }
            }
        }
        return clean;
    }

    function formatCanonicalAddress(addr, defaultPrefix) {
        if (!addr || addr === "-" || addr === "External Sender" || addr === "Active Account" || addr === "Destination Address" || addr === "zkVM Contract" || addr === "Logos L1" || addr === "LEZ Channel") {
            return addr || "-";
        }
        var str = String(addr).trim();
        if (str.toLowerCase().startsWith("public/")) {
            return "Public/" + str.substring(7).trim();
        }
        if (str.toLowerCase().startsWith("private/")) {
            return "Private/" + str.substring(8).trim();
        }
        return (defaultPrefix || "Public/") + str;
    }

    function getDisplayFrom() {
        if (!txData)
            return "-";
        var st = (txData.status || "").toLowerCase();
        if (st === "channel bridge" || (txData.detail && String(txData.detail).toLowerCase().indexOf("channel") !== -1)) {
            return "Logos L1";
        }
        if (txData.category === "Testimonials" || txData.category === "dApps" || st === "ledger" || st === "dapp") {
            var auth = txData.sender || txData.accountId || "Active Account";
            return formatCanonicalAddress(resolveFullAddress(auth), "Public/");
        }

        // Determine prefix (Public/ or Private/)
        var prefix = "Public/";
        var r = String(txData.route || "");
        var fromPart = r.indexOf("➝") !== -1 ? r.split("➝")[0] : (r.indexOf("→") !== -1 ? r.split("→")[0] : "");
        if (/private|shield/i.test(fromPart) || txData.status === "Unshield" || txData.status === "Private") {
            prefix = "Private/";
        }

        var addr = "";
        if (txData.sender && String(txData.sender).length > 0) {
            addr = String(txData.sender);
        } else if (txData.from && String(txData.from).length > 0) {
            addr = String(txData.from);
        } else if (txData.isIncoming) {
            addr = "External Sender";
        } else {
            addr = txData.accountId || ((accountStore && accountStore.activeAccount) ? accountStore.activeAccount.account_id : "Active Account");
        }

        addr = resolveFullAddress(addr);
        return formatCanonicalAddress(addr, prefix);
    }

    function getDisplayTo() {
        if (!txData)
            return "-";
        var st = (txData.status || "").toLowerCase();
        if (st === "channel bridge" || (txData.detail && String(txData.detail).toLowerCase().indexOf("channel") !== -1)) {
            return "LEZ Channel";
        }
        if (txData.category === "dApps" || st === "dapp") {
            if (txData.receiver && String(txData.receiver).length > 10 && txData.receiver !== "zkVM Contract") {
                return formatCanonicalAddress(resolveFullAddress(txData.receiver), "Public/");
            }
            return "Public/D7ADNV9oTPsS1qT5swbLsec4SZfsHodvJqkw4QqYGMBV";
        }
        if (txData.category === "Testimonials" || st === "ledger") {
            return "zkVM Contract";
        }

        // Determine prefix (Public/ or Private/)
        var prefix = "Public/";
        var r = String(txData.route || "");
        var toPart = r.indexOf("➝") !== -1 ? r.split("➝")[1] : (r.indexOf("→") !== -1 ? r.split("→")[1] : "");
        if (/private|shield/i.test(toPart) || txData.status === "Shield" || txData.status === "Private") {
            prefix = "Private/";
        }

        var addr = "";
        if (txData.receiver && String(txData.receiver).length > 0) {
            addr = String(txData.receiver);
        } else if (txData.to && String(txData.to).length > 0) {
            addr = String(txData.to);
        } else if (txData.isIncoming) {
            addr = txData.accountId || ((accountStore && accountStore.activeAccount) ? accountStore.activeAccount.account_id : "Active Account");
        } else {
            addr = txData.name || txData.detail || "Destination Address";
        }

        addr = resolveFullAddress(addr);
        return formatCanonicalAddress(addr, prefix);
    }

    function getDisplayHash() {
        if (!txData)
            return "-";
        if (txData.txHash && txData.txHash !== "-") {
            return txData.txHash;
        }
        if (txData.isIncoming) {
            return "External Inbound Transfer (Not Indexed)";
        }
        return "-";
    }

    Theme {
        id: theme
    }

    GasCalculator {
        id: gasCalc
    }

    Timer {
        id: resetCopyTimer
        interval: 2200
        repeat: false
        onTriggered: {
            modal.copyStatus = "";
        }
    }

    ColumnLayout {
        id: detailCol
        anchors.fill: parent
        spacing: 10

        // 1. AMOUNT & STATUS HERO
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 8
            spacing: 4

            // Total Token
            Text {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                text: {
                    if (!txData || !txData.amount || txData.amount === "-")
                        return "0 LEZ";
                    var amtStr = String(txData.amount).trim();
                    if (txData.category === "Testimonials" || txData.status === "Ledger")
                        return amtStr;
                    if (!/\s+[A-Za-z]+$/.test(amtStr)) {
                        return amtStr + " LEZ";
                    }
                    return amtStr;
                }
                color: {
                    if (!txData)
                        return theme.textPrimary;
                    var bStr = String(txData.block || "");
                    if (bStr.indexOf("Drop") !== -1 || bStr.indexOf("Failed") !== -1 || txData.isFailed === true) {
                        return theme.textMuted;
                    }
                    return txData.isIncoming ? theme.statusSuccess : theme.textPrimary;
                }
                font.strikeout: {
                    if (!txData)
                        return false;
                    var bStr = String(txData.block || "");
                    return (bStr.indexOf("Drop") !== -1 || bStr.indexOf("Failed") !== -1 || txData.isFailed === true);
                }
                font.family: theme.fontFamily
                font.pixelSize: 28
                font.weight: Font.Bold
            }

            // Status Tx
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: modal.getStatusText()
                color: modal.getStatusColor()
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeSmall
                font.weight: Font.Bold
            }
        }

        // 2. FROM & TO ADDRESS CARD
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: fromToCol.implicitHeight + 24
            radius: theme.radiusCard
            color: theme.bgSurface
            border.color: "transparent"
            border.width: 0

            ColumnLayout {
                id: fromToCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // From Label
                Text {
                    text: "From"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                // From Address Text
                Text {
                    Layout.fillWidth: true
                    text: modal.getDisplayFrom()
                    color: theme.textSecondary
                    font.family: theme.fontMono
                    font.pixelSize: theme.fontSizeSmall
                    wrapMode: Text.WrapAnywhere
                }

                // To Label
                Text {
                    text: "To"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                // To Address Text
                Text {
                    Layout.fillWidth: true
                    text: modal.getDisplayTo()
                    color: theme.textSecondary
                    font.family: theme.fontMono
                    font.pixelSize: theme.fontSizeSmall
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        // 3. TRANSACTION HASH CARD
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: txHashCol.implicitHeight + 24
            radius: theme.radiusCard
            color: theme.bgSurface
            border.color: "transparent"
            border.width: 0

            ColumnLayout {
                id: txHashCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Tx Hash Label (Judul warna putih)
                    Text {
                        text: "Tx Hash"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: Font.Medium
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: modal.copyStatus.length > 0
                        text: modal.copyStatus
                        color: theme.statusSuccess
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.Bold
                    }
                }

                // Card Hash
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: hashText.implicitHeight + 14
                    radius: theme.radiusSmall
                    color: theme.bgSurfaceSubtle
                    border.color: "transparent"
                    border.width: 0

                    Text {
                        id: hashText
                        anchors.fill: parent
                        anchors.margins: 7
                        text: modal.getDisplayHash()
                        color: hashHover.containsMouse ? theme.textPrimary : theme.textSecondary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                        font.underline: true
                        wrapMode: Text.WrapAnywhere
                        verticalAlignment: Text.AlignVCenter

                        MouseArea {
                            id: hashHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modal.txData) {
                                    var hash = modal.txData.txHash || "";
                                    if (hash && hash !== "-" && hash.indexOf("Not Indexed") === -1) {
                                        copyHelper.text = hash;
                                        copyHelper.selectAll();
                                        copyHelper.copy();
                                        modal.copyStatus = "Copied!";
                                        resetCopyTimer.restart();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 4. ON-CHAIN EXECUTION DETAILS CARD
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: telemetryCol.implicitHeight + 24
            radius: theme.radiusCard
            color: theme.bgSurface
            border.color: "transparent"
            border.width: 0

            ColumnLayout {
                id: telemetryCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 7

                // Optional Row: dApp Origin
                RowLayout {
                    Layout.fillWidth: true
                    visible: !!(txData && (txData.category === "dApps" || String(txData.status || "").toUpperCase() === "DAPP"))
                    Text {
                        text: "dApp Origin"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: txData ? (txData.dappName || txData.name || "External dApp") : "-"
                        color: theme.statusPublic
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: Font.DemiBold
                    }
                }

                // Optional Row: Contract Action Summary
                RowLayout {
                    Layout.fillWidth: true
                    visible: !!(txData && (txData.category === "dApps" || String(txData.status || "").toUpperCase() === "DAPP") && txData.detail)
                    Text {
                        text: "Contract Action"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        Layout.maximumWidth: 280
                        elide: Text.ElideRight
                        text: txData ? String(txData.detail || "-") : "-"
                        color: theme.textSecondary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                    }
                }

                // Row 1: Detailed Timestamp
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Timestamp (UTC)"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: {
                            if (!txData)
                                return "-";
                            var dt = String(txData.detailedTime || "").replace(/\s*\([^)]*\)$/, "").trim();
                            var ts = Number(txData.timestamp);
                            if (!ts && dt) {
                                var p = Date.parse(dt.replace(" UTC", "Z"));
                                if (!isNaN(p))
                                    ts = p;
                            }
                            if (ts) {
                                var diffMs = Date.now() - ts;
                                var rel = modal.formatRelativeAgo(diffMs);
                                return (dt ? dt : "") + (rel.length > 0 ? (" (" + rel + ")") : "");
                            }
                            return dt || (txData.time || "Just now");
                        }
                        color: theme.textSecondary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                    }
                }

                // Row 2: Block Inclusion
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Block Status / Height"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: {
                            if (!txData)
                                return "Block #...";
                            var bStr = String(txData.block || "");
                            if (bStr.indexOf("Drop") !== -1 || bStr.indexOf("Failed") !== -1 || txData.isFailed === true) {
                                return "Drop from mempool";
                            }
                            var isPending = (txData.block === "Pending" || txData.block === "Pending Block" || txData.block === "Sequencer Pending" || txData.isPending === true);
                            if (isPending) {
                                return "Sequencer Pending";
                            }
                            if (bStr.startsWith("Block #")) {
                                return bStr;
                            }
                            if (bStr && bStr !== "-" && bStr !== "Sequencer Confirmed") {
                                return "Block #" + bStr;
                            }
                            return "Block #...";
                        }
                        color: {
                            if (!txData)
                                return theme.statusSuccess;
                            var bStr = String(txData.block || "");
                            if (bStr.indexOf("Drop") !== -1 || bStr.indexOf("Failed") !== -1 || txData.isFailed === true) {
                                return theme.statusDanger;
                            }
                            var isPending = (txData.block === "Pending" || txData.block === "Pending Block" || txData.block === "Sequencer Pending" || txData.isPending === true);
                            return isPending ? theme.accentOrange : theme.statusSuccess;
                        }
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: Font.DemiBold
                    }
                }

                // Row 3: Actual Gas Used
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Actual Gas Used"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: txData ? gasCalc.normalizeDisplay(txData.gasUsed, txData.isIncoming, txData.category, txData.status, txData.detail) : "0"
                        color: theme.textSecondary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: Font.DemiBold
                    }
                }

                // Row 4: Route / Direction
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Privacy Routing"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: modal.getCleanRoute()
                        color: theme.textSecondary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                    }
                }

                // Row 5: Zone & Network
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Execution Zone"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "Logos LEZ Testnet"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                }
            }
        }
    }

    // Hidden clipboard copy helper
    TextEdit {
        id: copyHelper
        visible: false
    }
}
