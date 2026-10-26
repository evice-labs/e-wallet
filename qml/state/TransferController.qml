import QtQuick

Item {
    id: controller

    required property var bridge
    required property var accountStore

    property string destinationInput: ""
    property string amountInput: ""
    property string transferMode: "pub_to_pub" // "pub_to_pub", "pub_to_priv", "priv_to_pub", "priv_to_priv"
    property string resolvedTargetId: ""
    property string lnsStatus: "idle" // "idle", "resolving", "resolved", "invalid"
    property string lnsMessage: ""
    property string estimatedGas: "0.00015 LEZ"
    property bool isSubmitting: false
    property string lastRequestId: ""

    signal transferSuccess(string requestId)
    signal transferFailed(string reason)

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
            return;
        }

        if (trimmed.endsWith(".lez")) {
            lnsStatus = "resolving";
            lnsMessage = "Resolving on-chain LNS record...";
            resolveDebounce.restart();
        } else if (trimmed.startsWith("Public/") || trimmed.startsWith("Private/") || trimmed.length === 64) {
            lnsStatus = "resolved";
            lnsMessage = "Valid Account Identifier";
            resolvedTargetId = trimmed;
        } else {
            lnsStatus = "idle";
            lnsMessage = "";
            resolvedTargetId = trimmed;
        }
    }

    function executeResolution() {
        var name = destinationInput.trim();
        if (!name.endsWith(".lez")) return;

        bridge.invoke("resolveName", [bridge.activeSessionId, name], function(res) {
            if (res && res.ok && res.account_id) {
                controller.lnsStatus = "resolved";
                controller.resolvedTargetId = res.account_id;
                controller.lnsMessage = "Resolved to: " + res.account_id.substring(0, 18) + "...";
            } else {
                controller.lnsStatus = "invalid";
                controller.resolvedTargetId = "";
                controller.lnsMessage = res && res.error ? res.error : "Domain not found in LNS registry";
            }
        });
    }

    function validate(): var {
        var active = accountStore.activeAccount;
        if (!active) {
            return { valid: false, message: "No active account selected" };
        }

        var amt = parseFloat(amountInput);
        if (isNaN(amt) || amt <= 0) {
            return { valid: false, message: "Enter a valid positive amount" };
        }

        var bal = parseFloat(active.formatted_balance || "0") || 0;
        if (amt > bal) {
            return { valid: false, message: "Insufficient balance (" + amt + " > " + bal + " LEZ)" };
        }

        var dest = resolvedTargetId.length > 0 ? resolvedTargetId : destinationInput.trim();
        if (dest.length === 0) {
            return { valid: false, message: "Destination address or .lez name is required" };
        }

        if (destinationInput.trim().endsWith(".lez") && lnsStatus !== "resolved") {
            return { valid: false, message: "Cannot send to unverified LNS name" };
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
        // 1 LEZ = 1,000,000 micro-LEZ / unit
        var amountRaw = Math.round(check.amount * 1000000).toString();

        bridge.invoke("proposeNativeTransfer", [bridge.activeSessionId, fromAcc, dest, amountRaw], function(res) {
            controller.isSubmitting = false;
            if (res && res.ok) {
                controller.lastRequestId = res.request_id || "req_ok";
                controller.amountInput = "";
                controller.destinationInput = "";
                controller.transferSuccess(controller.lastRequestId);
                accountStore.refreshAccounts();
            } else {
                controller.transferFailed(res && res.error ? res.error : "Transfer submission failed");
            }
        });
    }
}
