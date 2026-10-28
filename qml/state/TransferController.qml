import QtQuick

Item {
    id: controller

    required property var bridge
    required property var accountStore

    property string destinationInput: ""
    property string amountInput: ""
    property string selectedAsset: "native" // "native" | "token"
    property var selectedToken: null
    property string transferMode: "pub_to_pub" // "pub_to_pub", "pub_to_priv", "priv_to_pub", "priv_to_priv"
    property string resolvedTargetId: ""
    property string lnsStatus: "idle" // "idle", "resolving", "resolved", "invalid"
    property string lnsMessage: ""
    property string estimatedGas: "0.00015 LEZ"
    property bool isSubmitting: false
    property string lastRequestId: ""
    property string lastTxHash: ""

    signal transferSuccess(string txHashOrReqId)
    signal transferFailed(string reason)

    // Automatically align default transfer mode when active account changes
    Connections {
        target: accountStore
        function onAccountSelected(acc) {
            controller.refreshRouteMode();
        }
        function onAccountsUpdated() {
            controller.refreshRouteMode();
        }
    }

    Component.onCompleted: {
        refreshRouteMode();
    }

    function refreshRouteMode() {
        var target = resolvedTargetId.length > 0 ? resolvedTargetId : destinationInput.trim();
        if (target.length > 0) {
            autoDetectMode(target);
        } else {
            updateDefaultMode();
        }
    }

    function updateDefaultMode() {
        var active = accountStore ? accountStore.activeAccount : null;
        var isSenderPriv = !!(active && active.is_private);
        transferMode = isSenderPriv ? "priv_to_priv" : "pub_to_pub";
    }

    // Debounce timer for LNS resolution
    Timer {
        id: resolveDebounce
        interval: 350
        repeat: false
        onTriggered: controller.executeResolution()
    }

    onDestinationInputChanged: {
        var trimmed = destinationInput.trim();
        if (trimmed.length === 0) {
            lnsStatus = "idle";
            lnsMessage = "";
            resolvedTargetId = "";
            updateDefaultMode();
            return;
        }

        if (trimmed.endsWith(".lez")) {
            lnsStatus = "resolving";
            lnsMessage = "Resolving on-chain LNS record...";
            resolveDebounce.restart();
        } else if (trimmed.toLowerCase().startsWith("public/") || trimmed.toLowerCase().startsWith("private/") || trimmed.length === 64) {
            lnsStatus = "resolved";
            resolvedTargetId = trimmed;
            autoDetectMode(trimmed);
            lnsMessage = trimmed.toLowerCase().startsWith("private/") ? "Shielded ZK Account Identifier" : "Public Transparent Account Identifier";
        } else {
            lnsStatus = "idle";
            lnsMessage = "";
            resolvedTargetId = trimmed;
            autoDetectMode(trimmed);
        }
    }

    function autoDetectMode(targetId) {
        var active = accountStore ? accountStore.activeAccount : null;
        var isSenderPriv = !!(active && active.is_private);
        var trimmed = (targetId || "").trim();
        var isDestPriv = trimmed.toLowerCase().startsWith("private/");

        if (isSenderPriv) {
            transferMode = isDestPriv ? "priv_to_priv" : "priv_to_pub";
        } else {
            transferMode = isDestPriv ? "pub_to_priv" : "pub_to_pub";
        }
    }

    function executeResolution() {
        var name = destinationInput.trim();
        if (!name.endsWith(".lez")) return;

        bridge.invoke("resolveName", [bridge.activeSessionId, name], function(res) {
            if (res && res.ok && res.account_id) {
                controller.lnsStatus = "resolved";
                controller.resolvedTargetId = res.account_id;
                autoDetectMode(res.account_id);
                controller.lnsMessage = "Resolved: " + res.account_id.substring(0, 16) + "...";
            } else {
                controller.lnsStatus = "invalid";
                controller.resolvedTargetId = "";
                controller.lnsMessage = res && res.error ? res.error : "Domain not found in LNS registry";
            }
        });
    }

    function setMaxAmount() {
        var active = accountStore.activeAccount;
        if (!active) return;

        if (selectedAsset === "token" && selectedToken) {
            var tokBal = parseFloat(selectedToken.formatted_balance ? selectedToken.formatted_balance.replace(/,/g, "") : "0") || 0;
            amountInput = tokBal > 0 ? tokBal.toString() : "0.00";
        } else {
            var bal = parseFloat(active.formatted_balance ? active.formatted_balance.replace(/,/g, "") : "0") || 0;
            var spendable = Math.max(0, bal - 0.00015);
            amountInput = spendable.toFixed(4);
        }
    }

    function validate(): var {
        var active = accountStore.activeAccount;
        if (!active) {
            return { valid: false, message: "No active account selected" };
        }

        var amt = parseFloat(amountInput);
        if (isNaN(amt) || amt <= 0) {
            return { valid: false, message: "Enter a valid positive transfer amount" };
        }

        if (selectedAsset === "token") {
            if (!selectedToken) {
                return { valid: false, message: "Select a valid token holding" };
            }
            var tokBal = parseFloat(selectedToken.formatted_balance ? selectedToken.formatted_balance.replace(/,/g, "") : "0") || 0;
            if (amt > tokBal) {
                return { valid: false, message: "Insufficient token balance (" + amt + " > " + tokBal + " " + selectedToken.symbol + ")" };
            }
        } else {
            var bal = parseFloat(active.formatted_balance ? active.formatted_balance.replace(/,/g, "") : "0") || 0;
            if (amt > bal) {
                return { valid: false, message: "Insufficient LEZ balance (" + amt + " > " + bal + " LEZ)" };
            }
        }

        var dest = resolvedTargetId.length > 0 ? resolvedTargetId : destinationInput.trim();
        if (dest.length === 0) {
            return { valid: false, message: "Destination address or .lez domain name is required" };
        }

        if (dest === active.account_id) {
            return { valid: false, message: "Self-transfer is not permitted" };
        }

        if (destinationInput.trim().endsWith(".lez") && lnsStatus !== "resolved") {
            return { valid: false, message: "Cannot send to unverified .lez name" };
        }

        return { valid: true, destination: dest, amount: amt };
    }

    function submitTransfer() {
        var check = validate();
        if (!check.valid) {
            transferFailed(check.message);
            return;
        }

        if (controller.isSubmitting) return;
        controller.isSubmitting = true;

        var active = accountStore.activeAccount;
        var fromAcc = active ? active.account_id : "";
        var dest = check.destination;

        if (selectedAsset === "token" && selectedToken) {
            // Fungible Token Transfer via Token Program
            var tokenAmountRaw = Math.round(check.amount * 1000000).toString();
            var fromHolding = selectedToken.holding_id || fromAcc;
            var toHolding = dest;
            var defId = selectedToken.definition_id || "Def/LOGO_GOVERNANCE_v1";

            bridge.invoke("proposeTokenTransfer", [bridge.activeSessionId, fromHolding, toHolding, defId, tokenAmountRaw], function(res) {
                handleProposalResponse(res);
            });
        } else {
            // Native LEZ Transfer (1 LEZ = 1,000,000 micro-LEZ)
            var amountRaw = Math.round(check.amount * 1000000).toString();

            bridge.invoke("proposeNativeTransfer", [bridge.activeSessionId, fromAcc, dest, amountRaw], function(res) {
                handleProposalResponse(res);
            });
        }
    }

    function handleProposalResponse(res) {
        if (res && res.ok) {
            controller.lastRequestId = res.request_id || "req_pending";
            // Check request confirmation / status
            bridge.invoke("getRequestStatus", [controller.lastRequestId], function(statusRes) {
                controller.isSubmitting = false;
                if (statusRes && statusRes.ok && statusRes.tx_hash) {
                    controller.lastTxHash = statusRes.tx_hash;
                } else {
                    controller.lastTxHash = controller.lastRequestId;
                }

                controller.amountInput = "";
                controller.destinationInput = "";
                controller.transferSuccess(controller.lastTxHash);
                accountStore.refreshAccounts();
                accountStore.refreshTokens();
            });
        } else {
            controller.isSubmitting = false;
            controller.transferFailed(res && res.error ? res.error : "Transfer submission failed");
        }
    }
}
