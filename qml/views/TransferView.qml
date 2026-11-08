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

    signal openUnlockModal

    property string feedbackMessage: ""
    property bool isSuccessFeedback: false

    Timer {
        id: feedbackDismissTimer
        interval: 4000
        repeat: false
        onTriggered: {
            transferCard.feedbackMessage = "";
        }
    }

    title: "Quick Transfer"

    Connections {
        target: transferCtrl
        function onTransferSuccess(txHash, amount, destination) {
            transferCard.isSuccessFeedback = true;
            var shortHash = txHash.length > 20 ? txHash.substring(0, 10) + "..." + txHash.substring(txHash.length - 8) : txHash;
            transferCard.feedbackMessage = "Transfer proposal submitted successfully! Ref: " + shortHash;
            feedbackDismissTimer.restart();
            if (transferCard.ledgerViewRef && transferCtrl) {
                var isPriv = transferCtrl.transferMode === "pub_to_priv" || transferCtrl.transferMode === "priv_to_priv";
                var modeLabel = isPriv ? "Shield" : (transferCtrl.transferMode === "priv_to_pub" ? "Unshield" : "Public");
                var cat = (isPriv || transferCtrl.transferMode === "priv_to_pub") ? "Shields" : "Transfers";
                var symbol = transferCtrl.selectedAsset === "token" ? (transferCtrl.selectedToken ? transferCtrl.selectedToken.symbol : "TOKEN") : "";
                var formattedOutAmount = symbol.length > 0 ? ("-" + actualAmount + " " + symbol) : ("-" + actualAmount);
                var formattedInAmount = symbol.length > 0 ? ("+" + actualAmount + " " + symbol) : ("+" + actualAmount);
                var senderId = (accountStore && accountStore.activeAccount) ? accountStore.activeAccount.account_id : "";
                var actualAmount = (amount && String(amount).length > 0) ? amount : (transferCtrl.amountInput || "0");
                var destTarget = (destination && String(destination).length > 0) ? destination : (transferCtrl.destinationInput || "Recipient");
                var destLabel = (accountStore && accountStore.getAccountLabel) ? accountStore.getAccountLabel(destTarget) : destTarget;
                var isToken = transferCtrl.selectedAsset === "token";
                var gasInfo = transferCtrl.calculateGas ? transferCtrl.calculateGas(transferCtrl.transferMode, isToken) : null;
                var gasFeeStr = gasInfo ? gasInfo.displayStr : "2,968";
                var gasLimitStr = gasInfo ? gasInfo.gasLimitFormatted : "34,000";

                var senderIsPriv = transferCtrl.transferMode === "priv_to_pub" || transferCtrl.transferMode === "priv_to_priv";
                var senderPrefix = senderIsPriv ? "Private/" : "Public/";
                var senderShort = senderId.length > 8 ? (senderId.substring(0, 8) + "...") : senderId;
                var senderRouteStr = senderPrefix + senderShort;

                var destIsPriv = transferCtrl.transferMode === "pub_to_priv" || transferCtrl.transferMode === "priv_to_priv";
                var destPrefix = destIsPriv ? "Private/" : "Public/";
                var cleanDestId = destTarget.replace("Private/", "").replace("Public/", "");
                var destShort = cleanDestId.length > 8 ? (cleanDestId.substring(0, 8) + "...") : cleanDestId;
                var destRouteStr = destPrefix + destShort;

                var detailedRoute = senderRouteStr + " ➝ " + destRouteStr;

                // 1. Record Outbound Activity on Sender Account
                transferCard.ledgerViewRef.addActivity(destLabel, modeLabel, cat, formattedOutAmount, isPriv ? "Zero-Knowledge Transfer" : "Public Transfer", false, txHash, gasFeeStr, "Pending", detailedRoute, senderId, gasLimitStr);

                // 2. If Intra-Wallet, immediately record Inbound Activity on Recipient Account
                if (accountStore && accountStore.accounts) {
                    for (var a = 0; a < accountStore.accounts.length; a++) {
                        var rAcc = accountStore.accounts[a];
                        if (rAcc.account_id === cleanDestId) {
                            var senderName = accountStore.getAccountLabel(accountStore.activeAccount);
                            var recStatus = destIsPriv ? "Shield" : "Deposit";
                            var recDetail = destIsPriv ? "Zero-Knowledge Inbound Transfer" : "Inbound Transfer";
                            transferCard.ledgerViewRef.addActivity(senderName, recStatus, "Transfers", formattedInAmount, recDetail, true, txHash, "0 (Paid by Sender)", "-", detailedRoute, rAcc.account_id, "0");
                            break;
                        }
                    }
                }
            }
            if (accountStore) {
                accountStore.refreshAccounts();
                accountStore.refreshTokens();
            }
        }
        function onTransferFailed(reason) {
            transferCard.isSuccessFeedback = false;
            transferCard.feedbackMessage = "Transfer failed: " + reason;
            feedbackDismissTimer.restart();
        }
        function onRequestUnlock() {
            transferCard.openUnlockModal();
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
                        if (transferCtrl)
                            transferCtrl.selectedAsset = "native";
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

            Item {
                Layout.fillWidth: true
            }
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
                        if (transferCtrl)
                            transferCtrl.selectedToken = modelData;
                    }
                }
            }

            Text {
                visible: !accountStore.tokens || accountStore.tokens.length === 0
                text: "No token holdings registered. Add one in Balance view."
                color: theme.accentOrange
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeSmall
            }
        }

        // Recipient Field with LNS Resolution Status
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            TextField {
                id: destField
                Layout.fillWidth: true
                placeholder: "Enter .lez domain name or account address..."
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
                visible: transferCtrl && transferCtrl.lnsStatus !== "idle" && (transferCtrl.lnsStatus !== "resolved" || transferCtrl.lnsMessage.length > 0)
                spacing: 6

                Text {
                    text: {
                        if (!transferCtrl)
                            return "";
                        if (transferCtrl.lnsStatus === "resolving")
                            return transferCtrl.destinationInput.endsWith(".lez") ? "RESOLVING LNS..." : "RESOLVING ADDRESS...";
                        if (transferCtrl.lnsStatus === "resolved")
                            return "RESOLVED";
                        if (transferCtrl.lnsStatus === "invalid")
                            return transferCtrl.destinationInput.endsWith(".lez") ? "INVALID DOMAIN" : "INVALID ADDRESS";
                        return "";
                    }
                    color: {
                        if (!transferCtrl)
                            return theme.textMuted;
                        if (transferCtrl.lnsStatus === "resolving")
                            return theme.accentOrange;
                        if (transferCtrl.lnsStatus === "resolved")
                            return theme.statusSuccess;
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
        }

        // Amount and Max Button
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: amtField
                Layout.fillWidth: true
                placeholder: "Amount: 0"
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

            RowLayout {
                spacing: 4

                Text {
                    text: (transferCtrl && (transferCtrl.transferMode === "priv_to_pub" || transferCtrl.transferMode === "priv_to_priv")) ? "Shield" : "Public"
                    color: (transferCtrl && (transferCtrl.transferMode === "priv_to_pub" || transferCtrl.transferMode === "priv_to_priv")) ? theme.statusShielded : theme.statusPublic
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTiny
                    font.weight: Font.Bold
                }

                Text {
                    text: "➝"
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTiny
                    font.weight: Font.Bold
                }

                Text {
                    text: (transferCtrl && (transferCtrl.transferMode === "pub_to_priv" || transferCtrl.transferMode === "priv_to_priv")) ? "Shield" : "Public"
                    color: (transferCtrl && (transferCtrl.transferMode === "pub_to_priv" || transferCtrl.transferMode === "priv_to_priv")) ? theme.statusShielded : theme.statusPublic
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTiny
                    font.weight: Font.Bold
                }
            }
        }

        // FLEXIBLE EXPANDING SPACER
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // Status / Feedback Banner (Auto-dismissing)
        Text {
            visible: transferCard.feedbackMessage.length > 0
            text: transferCard.feedbackMessage
            color: transferCard.isSuccessFeedback ? theme.statusSuccess : theme.statusDanger
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.bottomMargin: 2
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
                text: "Gas Limit: " + (transferCtrl ? String(transferCtrl.estimatedGas || "34,000").replace(/\s*units\b/gi, "").trim() : "34,000")
                color: theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
                Layout.alignment: Qt.AlignVCenter
            }

            Item {
                Layout.fillWidth: true
            }

            // 2. Submit Action Button
            Button {
                text: {
                    if (transferCtrl && transferCtrl.isSubmitting)
                        return "Submitting...";
                    if (bridge.isLocked)
                        return "Unlock Vault";
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
                        feedbackDismissTimer.restart();
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
    }
}
