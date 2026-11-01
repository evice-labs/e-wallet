import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "Transaction Details"
    dialogWidth: 560
    dialogHeight: 480

    property var txData: null
    property string copyStatus: ""

    Theme { id: theme }

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
                    if (!txData) return theme.statusPublic;
                    var st = txData.status;
                    if (st === "Private" || st === "Shield") return theme.statusShielded;
                    if (st === "Unshield") return theme.statusSuccess;
                    if (st === "Faucet" || st === "Ledger") return theme.accentOrange;
                    return theme.statusPublic;
                }
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTiny
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true }

            Text {
                text: txData ? txData.amount : "0.00 LEZ"
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
                            text: txData ? (txData.txHash || "0x9f538361b55c890f9bd5dae00cf98d4bb677cc3bd129c0147fbe4b23fccaf184") : ""
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
                    customWidth: 70
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: {
                        if (modal.txData) {
                            var hash = modal.txData.txHash || "0x9f538361b55c890f9bd5dae00cf98d4bb677cc3bd129c0147fbe4b23fccaf184";
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
                    Item { Layout.fillWidth: true }
                    Text {
                        text: txData ? (txData.detailedTime || (txData.time ? ("2026-10-30 17:35:10 UTC (" + txData.time + ")") : "2026-10-30 17:35:10 UTC")) : "2026-10-30 17:35:10 UTC"
                        color: theme.textPrimary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                    }
                }

                // Row 2: Block Height
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Block Height Included:"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: txData ? ("Block #" + (txData.block || 43565)) : "Block #43565"
                        color: theme.accentOrange
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: Font.DemiBold
                    }
                }

                // Row 3: Gas Used vs Gas Limit
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Actual Gas Used:"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: txData ? (txData.gasUsed || "34,000 units (0.00015 LEZ)") : "34,000 units"
                        color: theme.statusSuccess
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: Font.DemiBold
                    }
                }

                // Row 4: Gas Limit
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Gas Limit Declared:"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: txData ? (txData.gasLimit ? (txData.gasLimit + " units") : "34,000 units") : "34,000 units"
                        color: theme.textPrimary
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
                    Item { Layout.fillWidth: true }
                    Text {
                        text: txData ? (txData.route || "Public ➝ Public") : "Public ➝ Public"
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
                    Item { Layout.fillWidth: true }
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

        Item { Layout.fillHeight: true }

        // FOOTER ACTIONS
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: "Open Explorer"
                isPrimary: false
                isCompact: true
                onClicked: {
                    var hash = (modal.txData && modal.txData.txHash) ? modal.txData.txHash : "";
                    var url = "https://explorer.testnet.lez.logos.co/";
                    if (hash && hash.length > 10) {
                        url = "https://explorer.testnet.lez.logos.co/tx/" + hash;
                    }
                    Qt.openUrlExternally(url);
                }
            }
        }
    }
}
