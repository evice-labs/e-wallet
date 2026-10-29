import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Card {
    id: transferCard

    required property var bridge
    required property var accountStore
    property var transferCtrl: null
    property var ledgerViewRef: null

    implicitHeight: 295

    signal openUnlockModal()

    property string feedbackMessage: ""
    property bool isSuccessFeedback: false

    title: "Quick Transfer"

    Connections {
        target: transferCtrl
        function onTransferSuccess(txHash) {
            transferCard.isSuccessFeedback = true;
            var shortHash = txHash.length > 20 ? txHash.substring(0, 10) + "..." + txHash.substring(txHash.length - 8) : txHash;
            transferCard.feedbackMessage = "Transfer proposal submitted successfully! Ref: " + shortHash;
            if (transferCard.ledgerViewRef && transferCtrl) {
                var isPriv = transferCtrl.transferMode === "pub_to_priv" || transferCtrl.transferMode === "priv_to_priv";
                var modeLabel = isPriv ? "Shield" : (transferCtrl.transferMode === "priv_to_pub" ? "Unshield" : "Public");
                var cat = (isPriv || transferCtrl.transferMode === "priv_to_pub") ? "Shields" : "Transfers";
                var symbol = transferCtrl.selectedAsset === "token" ? (transferCtrl.selectedToken ? transferCtrl.selectedToken.symbol : "TOKEN") : "LEZ";
                transferCard.ledgerViewRef.addActivity(
                    transferCtrl.destinationInput || "Recipient",
                    modeLabel,
                    cat,
                    "-" + transferCtrl.amountInput + " " + symbol,
                    isPriv ? "Zero-Knowledge Transfer" : "Public Transfer",
                    false
                );
            }
        }
        function onTransferFailed(reason) {
            transferCard.isSuccessFeedback = false;
            transferCard.feedbackMessage = "Transfer failed: " + reason;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // BODY: Asset, Recipient & Amount Inputs

        // Asset Selector (Native LEZ vs Token Program)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Asset:"
                color: theme.textSecondary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeSmall
            }

            SegmentedBar {
                TabButton {
                    text: "Native LEZ"
                    isActive: !transferCtrl || transferCtrl.selectedAsset === "native"
                    onClicked: {
                        if (transferCtrl) transferCtrl.selectedAsset = "native";
                    }
                }

                TabButton {
                    text: "Tokens"
                    isActive: transferCtrl && transferCtrl.selectedAsset === "token"
                    onClicked: {
                        if (transferCtrl) {
                            transferCtrl.selectedAsset = "token";
                            if (!transferCtrl.selectedToken && accountStore.tokens && accountStore.tokens.length > 0) {
                                transferCtrl.selectedToken = accountStore.tokens[0];
                            }
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }
        }

        // Token Holding Selector (Visible when Asset == Token)
        RowLayout {
            visible: transferCtrl && transferCtrl.selectedAsset === "token"
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Holding:"
                color: theme.textSecondary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeSmall
            }

            Repeater {
                model: accountStore.tokens || []
                delegate: Button {
                    isCompact: true
                    text: modelData.symbol + " (" + (modelData.formatted_balance || "0") + ")"
                    isPrimary: transferCtrl && transferCtrl.selectedToken && transferCtrl.selectedToken.holding_id === modelData.holding_id
                    onClicked: {
                        if (transferCtrl) transferCtrl.selectedToken = modelData;
                    }
                }
            }
        }

        // Recipient Field with LNS Resolution Status
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            TextField {
                id: destField
                Layout.fillWidth: true
                placeholder: "To: bob.lez or Address"
                text: transferCtrl ? transferCtrl.destinationInput : ""
                onTextChanged: {
                    if (transferCtrl && transferCtrl.destinationInput !== text) {
                        transferCtrl.destinationInput = text;
                    }
                }
            }

            Connections {
                target: transferCtrl
                function onDestinationInputChanged() {
                    if (destField.text !== (transferCtrl ? transferCtrl.destinationInput : "")) {
                        destField.text = transferCtrl ? transferCtrl.destinationInput : "";
                    }
                }
            }

            // Real-Time LNS / Account Validation Typographic Text
            RowLayout {
                visible: transferCtrl && transferCtrl.lnsStatus !== "idle"
                spacing: 6

                Text {
                    text: {
                        if (!transferCtrl) return "";
                        if (transferCtrl.lnsStatus === "resolving") return "RESOLVING LNS...";
                        if (transferCtrl.lnsStatus === "resolved") return "RESOLVED";
                        if (transferCtrl.lnsStatus === "invalid") return "INVALID DOMAIN";
                        return "";
                    }
                    color: {
                        if (!transferCtrl) return theme.textMuted;
                        if (transferCtrl.lnsStatus === "resolving") return theme.accentOrange;
                        if (transferCtrl.lnsStatus === "resolved") return theme.statusSuccess;
                        return theme.statusDanger;
                    }
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTiny
                    font.weight: Font.Bold
                }

                Text {
                    text: transferCtrl ? transferCtrl.lnsMessage : ""
                    color: transferCtrl && transferCtrl.lnsStatus === "invalid" ? theme.statusDanger : theme.textSecondary
                    font.family: theme.fontMono
                    font.pixelSize: theme.fontSizeSmall
                    elide: Text.ElideRight
                }
            }

            // Quick Recipient Selection for User's Other Accounts
            RowLayout {
                visible: accountStore.accounts && accountStore.accounts.length > 1
                spacing: 6

                Text {
                    text: "Your Accounts:"
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTiny
                }

                Repeater {
                    model: {
                        if (!accountStore || !accountStore.accounts) return [];
                        var list = [];
                        var active = accountStore.activeAccount;
                        for (var i = 0; i < accountStore.accounts.length; i++) {
                            var a = accountStore.accounts[i];
                            if (!active || a.account_id !== active.account_id) {
                                list.push(a);
                            }
                        }
                        return list;
                    }
                    delegate: Button {
                        isCompact: true
                        text: (modelData.label || "Account") + (modelData.is_private ? " (Shielded)" : "")
                        onClicked: {
                            if (transferCtrl) {
                                transferCtrl.destinationInput = modelData.account_id;
                            }
                        }
                    }
                }
            }
        }

        // Amount and Max Button
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: amtField
                Layout.fillWidth: true
                placeholder: "Amount: 0.00"
                text: transferCtrl ? transferCtrl.amountInput : ""
                onTextChanged: {
                    if (transferCtrl && transferCtrl.amountInput !== text) {
                        transferCtrl.amountInput = text;
                    }
                }
            }

            Button {
                text: "Max"
                isCompact: true
                onClicked: {
                    if (transferCtrl) {
                        transferCtrl.setMaxAmount();
                    }
                }
            }
        }

        // Automatic Route Indicator
        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Text {
                text: "Route:"
                color: theme.textPrimary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTiny
                font.weight: Font.Medium
            }

            Text {
                text: {
                    if (!transferCtrl) return "Public ➝ Public";
                    if (transferCtrl.transferMode === "pub_to_priv") return "Public ➝ Shield";
                    if (transferCtrl.transferMode === "priv_to_pub") return "Shield ➝ Public";
                    if (transferCtrl.transferMode === "priv_to_priv") return "Shield ➝ Shield";
                    return "Public ➝ Public";
                }
                color: (transferCtrl && (transferCtrl.transferMode === "pub_to_priv" || transferCtrl.transferMode === "priv_to_priv")) ? theme.statusShielded : theme.statusPublic
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTiny
                font.weight: Font.Bold
            }
        }

        // FLEXIBLE EXPANDING SPACER
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // STATIC FOOTER: Telemetry & Action Button
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // Telemetry & Submit Action (Inline)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // 1. Est. Gas Telemetry
            Text {
                text: "Est. Gas: " + (transferCtrl ? transferCtrl.estimatedGas : "0.00015 LEZ")
                color: theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
                Layout.alignment: Qt.AlignVCenter
            }

            Item { Layout.fillWidth: true }

            // 2. Submit Action Button
            Button {
                text: {
                    if (transferCtrl && transferCtrl.isSubmitting) return "Submitting...";
                    if (bridge.isLocked) return "Unlock Vault";
                    return "Send Transfer";
                }
                isPrimary: true
                isCompact: true
                customHeight: 34
                Layout.alignment: Qt.AlignVCenter
                enabled: !transferCtrl || (!transferCtrl.isSubmitting)
                onClicked: {
                    if (bridge.isLocked) {
                        transferCard.feedbackMessage = "Vault is locked. Please unlock your keystore.";
                        transferCard.isSuccessFeedback = false;
                        transferCard.openUnlockModal();
                        return;
                    }

                    if (transferCtrl) {
                        transferCard.feedbackMessage = "";
                        transferCtrl.submitTransfer();
                    }
                }
            }
        }

        // Feedback / Error Telemetry
        Text {
            visible: transferCard.feedbackMessage.length > 0
            text: transferCard.feedbackMessage
            color: transferCard.isSuccessFeedback ? theme.statusSuccess : theme.statusDanger
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
