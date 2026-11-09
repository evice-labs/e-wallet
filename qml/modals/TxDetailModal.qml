import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"
import "../state"

ModalOverlay {
    id: modal

    title: "Transaction Details"
    dialogWidth: 560
    dialogHeight: 430

    property var txData: null
    property string copyStatus: ""

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
        anchors.fill: parent
        spacing: 12

        // HEADER: Direction Badge & Amount Callout
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: txData ? (txData.status || "Public").toUpperCase() : "PUBLIC"
                color: {
                    if (!txData)
                        return theme.statusPublic;
                    var st = txData.status;
                    if (st === "Private" || st === "Shield")
                        return theme.statusShielded;
                    if (st === "Unshield")
                        return theme.statusSuccess;
                    if (st === "Faucet" || st === "Ledger")
                        return theme.accentOrange;
                    return theme.statusPublic;
                }
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTiny
                font.weight: Font.Bold
            }

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: {
                    if (!txData || !txData.amount || txData.amount === "-")
                        return "0";
                    return String(txData.amount).replace(/\s*LEZ\b/gi, "").trim();
                }
                color: (txData && txData.isIncoming) ? theme.statusSuccess : theme.textPrimary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTitle + 2
                font.weight: Font.Bold
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // TRANSACTION HASH
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "TRANSACTION HASH"
                color: theme.textSecondary
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeTiny
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                InsetPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: txData ? (txData.txHash && txData.txHash !== "-" ? txData.txHash : (txData.isIncoming ? "External Inbound Transfer (Not Indexed)" : "-")) : ""
                            color: theme.textPrimary
                            font.family: theme.fontMono
                            font.pixelSize: theme.fontSizeTiny
                            wrapMode: Text.NoWrap
                            elide: Text.ElideMiddle
                        }
                    }
                }

                Button {
                    text: modal.copyStatus.length > 0 ? modal.copyStatus : "Copy"
                    isCompact: true
                    isPrimary: modal.copyStatus.length === 0
                    customHeight: 34
                    customWidth: 78
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: {
                        if (modal.txData) {
                            var hash = modal.txData.txHash || "";
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

        // GAS USAGE & ON-CHAIN EXECUTION TELEMETRY
        Card {
            Layout.fillWidth: true
            Layout.preferredHeight: telemetryCol.implicitHeight + 34

            ColumnLayout {
                id: telemetryCol
                width: parent.width
                spacing: 7

                // Row 1: Detailed Timestamp
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Timestamp (UTC):"
                        color: theme.textSecondary
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
                            var dt = (txData.detailedTime || "").replace(" (Just now)", "");
                            var ts = Number(txData.timestamp);
                            if (!ts && dt) {
                                var p = Date.parse(dt.replace(" UTC", "Z"));
                                if (!isNaN(p))
                                    ts = p;
                            }
                            if (ts) {
                                var diffMin = Math.max(0, Math.floor((Date.now() - ts) / 60000));
                                var rel = diffMin === 0 ? " (Just now)" : (" (" + diffMin + " min" + (diffMin === 1 ? "" : "s") + " ago)");
                                return dt + rel;
                            }
                            return dt || (txData.time || "Just now");
                        }
                        color: theme.textPrimary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                    }
                }

                // Row 2: Block Inclusion
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Block Status / Height:"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: {
                            if (!txData)
                                return "Sequencer Confirmed";
                            var isPending = (txData.block === "Pending" || txData.block === "Pending Block" || txData.isPending === true);
                            if (isPending) {
                                return "Sequencer Pending";
                            }
                            var bStr = String(txData.block || "");
                            if (!txData.block || bStr === "-" || bStr === "Sequencer Confirmed") {
                                return "Sequencer Confirmed";
                            }
                            if (bStr === "Pending" || bStr === "Pending Block") {
                                return "Sequencer Pending";
                            }
                            return bStr.startsWith("Block #") ? (bStr + " • Sequencer Confirmed") : ("Block #" + bStr + " • Sequencer Confirmed");
                        }
                        color: {
                            if (!txData)
                                return theme.statusSuccess;
                            var isPending = (txData.block === "Pending" || txData.block === "Pending Block" || txData.isPending === true);
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
                        text: "Actual Gas Used:"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: {
                            if (!txData)
                                return "0";
                            return gasCalc.normalizeDisplay(txData.gasUsed, txData.isIncoming, txData.category, txData.status, txData.detail);
                        }
                        color: (txData && txData.isIncoming) ? theme.statusSuccess : theme.textPrimary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: Font.DemiBold
                    }
                }

                // Row 4: Declared Gas Limit
                RowLayout {
                    Layout.fillWidth: true
                    visible: !(txData && txData.isIncoming)
                    Text {
                        text: "Gas Limit Declared:"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: {
                            if (!txData)
                                return "34,000";
                            var lim = String(txData.gasLimit || "34,000").replace(/\s*units\b/gi, "").trim();
                            return lim || "34,000";
                        }
                        color: theme.textSecondary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                    }
                }

                // Row 5: Route / Direction
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Privacy Routing:"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: (txData && txData.route) ? txData.route : "Public ➝ Public"
                        color: theme.textPrimary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                    }
                }

                // Row 6: Zone & Network
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Execution Zone:"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: "Logos LEZ (Testnet 0.4)"
                        color: theme.textMuted
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                }
            }
        }

        // Hidden clipboard copy helper
        TextEdit {
            id: copyHelper
            visible: false
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
