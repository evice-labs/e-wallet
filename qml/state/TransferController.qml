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
    property int gasLimitValue: 34000
    property string estimatedGas: "34,000"
    property bool isSubmitting: false
    property string lastRequestId: ""
    property string lastTxHash: ""

    GasCalculator {
        id: gasCalc
    }

    signal transferSuccess(string txHashOrReqId, string sentAmount, string sentDestination)
    signal transferFailed(string reason)
    signal requestUnlock

    function calculateGas(mode, isToken) {
        return gasCalc.calculateTransferGas(mode, isToken);
    }

    function updateEstimatedGas() {
        var isPriv = transferMode === "priv_to_pub" || transferMode === "priv_to_priv";
        if (isPriv) {
            controller.estimatedGas = "500,000";
        } else {
            var limit = controller.gasLimitValue > 0 ? controller.gasLimitValue : 34000;
            controller.estimatedGas = Number(limit).toLocaleString();
        }
    }

    onTransferModeChanged: {
        updateEstimatedGas();
    }

    function refreshGasLimit() {
        if (!bridge)
            return;
        bridge.invoke("getGasLimit", [], function (res) {
            if (res && res.ok && res.gas_limit) {
                controller.gasLimitValue = res.gas_limit;
                updateEstimatedGas();
            }
        });
    }

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
        refreshGasLimit();
    }

    function refreshRouteMode() {
        if (destinationInput.trim().length > 0) {
            autoDetectMode(destinationInput.trim());
        } else {
            updateDefaultMode();
        }
    }

    function updateDefaultMode() {
        var active = accountStore ? accountStore.activeAccount : null;
        var isSenderPriv = !!(active && (active.is_private === true || active.privacy === "private"));
        transferMode = isSenderPriv ? "priv_to_priv" : "pub_to_pub";
    }

    // Debounce timer for universal account and name resolution
    Timer {
        id: resolveDebounce
        interval: 300
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
        } else {
            var clientRes = resolveClientSide(trimmed);
            if (clientRes) {
                applyResolution(clientRes);
            } else {
                lnsStatus = "idle";
                lnsMessage = "";
            }
            resolveDebounce.restart();
        }
    }

    function autoDetectMode(targetId) {
        var active = accountStore ? accountStore.activeAccount : null;
        var isSenderPriv = !!(active && (active.is_private === true || active.privacy === "private"));

        var trimmed = (targetId || destinationInput || "").trim();
        var lower = trimmed.toLowerCase();
        var isDestPriv = false;
        if (lower.startsWith("private/")) {
            isDestPriv = true;
        } else if (lower.startsWith("public/")) {
            isDestPriv = false;
        } else {
            var clean = trimmed.replace(/^public\//i, "").replace(/^private\//i, "");
            var local = findLocalAccount(clean);
            isDestPriv = (local && (local.is_private === true || local.privacy === "private"));
        }

        if (isSenderPriv) {
            transferMode = isDestPriv ? "priv_to_priv" : "priv_to_pub";
        } else {
            transferMode = isDestPriv ? "pub_to_priv" : "pub_to_pub";
        }
    }

    function findLocalAccount(rawId) {
        if (!accountStore || !Array.isArray(accountStore.accounts))
            return null;
        for (var i = 0; i < accountStore.accounts.length; i++) {
            var acc = accountStore.accounts[i];
            if (acc && acc.account_id === rawId) {
                return acc;
            }
        }
        return null;
    }

    function resolveClientSide(input) {
        var trimmed = (input || "").trim();
        if (!trimmed)
            return null;

        var lower = trimmed.toLowerCase();
        var isExplicitPriv = lower.startsWith("private/");
        var isExplicitPub = lower.startsWith("public/");

        if (isExplicitPriv || isExplicitPub) {
            var rawId = trimmed.substring(isExplicitPriv ? 8 : 7).trim();
            var matched = findLocalAccount(rawId);
            var label = matched ? (matched.label || "") : "";
            return {
                account_id: rawId,
                canonical_address: isExplicitPriv ? ("Private/" + rawId) : ("Public/" + rawId),
                privacy: isExplicitPriv ? "private" : "public",
                label: label
            };
        }

        // Check if raw Base58 address (42 to 45 chars)
        if (/^[1-9A-HJ-NP-Za-km-z]{42,45}$/.test(trimmed)) {
            var matchedB58 = findLocalAccount(trimmed);
            var isPriv = matchedB58 ? (matchedB58.is_private === true || matchedB58.privacy === "private") : false;
            var labelB58 = matchedB58 ? (matchedB58.label || "") : "";
            return {
                account_id: trimmed,
                canonical_address: isPriv ? ("Private/" + trimmed) : ("Public/" + trimmed),
                privacy: isPriv ? "private" : "public",
                label: labelB58
            };
        }

        return null;
    }

    function applyResolution(res) {
        if (!res || !res.account_id)
            return;
        controller.lnsStatus = "resolved";
        controller.resolvedTargetId = res.account_id;

        var active = accountStore ? accountStore.activeAccount : null;
        var isSenderPriv = !!(active && (active.is_private === true || active.privacy === "private"));

        var isDestPriv = false;
        if (res.canonical_address && res.canonical_address.toLowerCase().startsWith("private/")) {
            isDestPriv = true;
        } else if (res.canonical_address && res.canonical_address.toLowerCase().startsWith("public/")) {
            isDestPriv = false;
        } else {
            isDestPriv = (res.privacy === "private");
        }

        if (isSenderPriv) {
            controller.transferMode = isDestPriv ? "priv_to_priv" : "priv_to_pub";
        } else {
            controller.transferMode = isDestPriv ? "pub_to_priv" : "pub_to_pub";
        }

        if (res.label && res.label.trim().length > 0) {
            controller.lnsMessage = res.label.trim();
        } else if (destinationInput.trim().endsWith(".lez")) {
            controller.lnsMessage = "Resolved domain: " + destinationInput.trim();
        } else {
            controller.lnsMessage = "";
        }
    }

    function executeResolution() {
        var input = destinationInput.trim();
        if (input.length === 0) {
            lnsStatus = "idle";
            lnsMessage = "";
            resolvedTargetId = "";
            updateDefaultMode();
            return;
        }

        // 1. Immediate client-side resolution for explicit prefixes & raw Base58
        var clientRes = resolveClientSide(input);
        if (clientRes) {
            applyResolution(clientRes);
        }

        // 2. Query backend facade (resolveAccount or fallback to resolveName for .lez)
        bridge.invoke("resolveAccount", [input], function (res) {
            if (res && res.ok && res.account_id) {
                applyResolution(res);
            } else if (res && res.error && res.error.indexOf("Method not found") !== -1) {
                // Backend lacks resolveAccount (older binary)
                if (input.endsWith(".lez")) {
                    bridge.invoke("resolveName", [bridge.activeSessionId, input], function (resName) {
                        if (resName && resName.ok && resName.account_id) {
                            applyResolution({
                                account_id: resName.account_id,
                                canonical_address: "Public/" + resName.account_id,
                                privacy: "public",
                                label: input
                            });
                        } else {
                            controller.lnsStatus = "invalid";
                            controller.resolvedTargetId = "";
                            controller.lnsMessage = resName && resName.error ? resName.error : "Domain not found in LNS registry";
                            updateDefaultMode();
                        }
                    });
                } else if (!clientRes) {
                    controller.lnsStatus = "invalid";
                    controller.resolvedTargetId = "";
                    controller.lnsMessage = "Invalid recipient address or domain";
                    updateDefaultMode();
                }
            } else if (input.endsWith(".lez")) {
                controller.lnsStatus = "invalid";
                controller.resolvedTargetId = "";
                controller.lnsMessage = res && res.error ? res.error : "Domain not found in LNS registry";
                updateDefaultMode();
            } else if (!clientRes) {
                controller.lnsStatus = "invalid";
                controller.resolvedTargetId = "";
                controller.lnsMessage = res && res.error ? res.error : "Unknown destination address";
                updateDefaultMode();
            }
        });
    }

    function setMaxAmount() {
        var active = accountStore.activeAccount;
        if (!active)
            return;

        if (selectedAsset === "token" && selectedToken) {
            var tokBal = parseFloat(selectedToken.formatted_balance ? selectedToken.formatted_balance.replace(/,/g, "") : "0") || 0;
            amountInput = tokBal > 0 ? Math.floor(tokBal).toString() : "0";
        } else {
            var isSenderPriv = (transferMode === "priv_to_pub" || transferMode === "priv_to_priv");
            var poolBalStr = isSenderPriv ? accountStore.activeShieldedBalance : accountStore.activePublicBalance;
            var bal = parseFloat(poolBalStr ? String(poolBalStr).replace(/,/g, "") : "0") || 0;
            var limit = controller.gasLimitValue > 0 ? controller.gasLimitValue : 34000;
            var spendable = isSenderPriv ? bal : Math.max(0, bal - limit);
            amountInput = spendable > 0 ? Math.floor(spendable).toString() : "0";
        }
    }

    function validate(): var {
        var active = accountStore.activeAccount;
        if (!active) {
            return {
                valid: false,
                message: "No active account selected"
            };
        }

        var cleanAmtStr = String(amountInput || "").replace(/,/g, "").trim();
        var amt = parseFloat(cleanAmtStr);
        if (isNaN(amt) || amt <= 0) {
            return {
                valid: false,
                message: "Enter a valid positive transfer amount"
            };
        }

        if (selectedAsset === "token") {
            if (!selectedToken) {
                return {
                    valid: false,
                    message: "Select a valid token holding"
                };
            }
            var tokBal = parseFloat(selectedToken.formatted_balance ? selectedToken.formatted_balance.replace(/,/g, "") : "0") || 0;
            if (amt > tokBal) {
                return {
                    valid: false,
                    message: "Insufficient token balance (" + amt + " > " + tokBal + " " + selectedToken.symbol + ")"
                };
            }
        } else {
            var isSenderPriv = (transferMode === "priv_to_pub" || transferMode === "priv_to_priv");
            var poolBalStr = isSenderPriv ? accountStore.activeShieldedBalance : accountStore.activePublicBalance;
            var poolBal = parseFloat(poolBalStr ? String(poolBalStr).replace(/,/g, "") : "0") || 0;
            if (amt > poolBal) {
                return {
                    valid: false,
                    message: "Insufficient " + (isSenderPriv ? "shielded" : "public") + " balance (" + amt + " > " + poolBal + " LEZ)"
                };
            }
        }

        var dest = resolvedTargetId.length > 0 ? resolvedTargetId : destinationInput.trim();
        if (dest.length === 0) {
            return {
                valid: false,
                message: "Destination address or .lez domain name is required"
            };
        }

        var cleanDestId = dest.replace(/^public\//i, "").replace(/^private\//i, "");
        var isSenderPrivMode = (transferMode === "priv_to_pub" || transferMode === "priv_to_priv");
        var isDestPrivMode = (transferMode === "pub_to_priv" || transferMode === "priv_to_priv");
        if (cleanDestId === active.account_id && isSenderPrivMode === isDestPrivMode) {
            return {
                valid: false,
                message: "Self-transfer is not permitted. Please specify a different recipient address."
            };
        }

        if (selectedAsset !== "token" && isDestPrivMode && !isSenderPrivMode) {
            var localDest = findLocalAccount(cleanDestId);
            var destExistingBal = localDest ? (parseFloat(localDest.balance || "0") || 0) : 0;
            if (localDest && (localDest.is_private === true || localDest.privacy === "private") && (destExistingBal + amt <= 5070616)) {
                return {
                    valid: false,
                    message: "Shielding to a 0-balance private account requires > 5,070,616 LEZ raw units to cover the private execution fee reserve."
                };
            }
        }

        if (destinationInput.trim().endsWith(".lez") && lnsStatus !== "resolved") {
            return {
                valid: false,
                message: "Cannot send to unverified .lez name"
            };
        }

        return {
            valid: true,
            destination: dest,
            amount: amt
        };
    }

    function submitTransfer() {
        var check = validate();
        if (!check.valid) {
            transferFailed(check.message);
            return;
        }

        if (controller.isSubmitting)
            return;
        controller.isSubmitting = true;

        var active = accountStore.activeAccount;
        var fromAcc = active ? active.account_id : "";
        var dest = check.destination;

        executeProposal(fromAcc, dest, check.amount, false);
    }

    Timer {
        id: proposalStatusTimer
        interval: 500
        repeat: false
        property var callback: null
        onTriggered: {
            if (callback)
                callback();
        }
    }

    function executeProposal(fromAcc, dest, amt, isRetry) {
        bridge.ensureActiveSession(function (sessRes) {
            var sessId = (sessRes && sessRes.session_id) ? sessRes.session_id : bridge.activeSessionId;

            if (!sessId || sessId.length === 0) {
                // Direct connect fallback
                bridge.invoke("connectDApp", ["internal_wallet_ui", 1], function (connRes) {
                    if (connRes && connRes.ok && connRes.session_id) {
                        bridge.activeSessionId = connRes.session_id;
                        proceedProposalWithSession(connRes.session_id, fromAcc, dest, amt, isRetry);
                    } else {
                        controller.isSubmitting = false;
                        var errStr = (connRes && connRes.error) ? String(connRes.error) : "";
                        if (errStr.indexOf("WalletLocked") !== -1 || errStr.indexOf("locked") !== -1) {
                            controller.transferFailed("Vault is locked in backend. Please unlock your keystore vault to authorize.");
                            controller.requestUnlock();
                        } else {
                            controller.transferFailed("Unable to establish active wallet session: " + (errStr || "Unknown error"));
                        }
                    }
                });
                return;
            }

            proceedProposalWithSession(sessId, fromAcc, dest, amt, isRetry);
        });
    }

    function proceedProposalWithSession(sessId, fromAcc, dest, amt, isRetry) {
        var cleanFrom = fromAcc.replace(/^public\//i, "").replace(/^private\//i, "");
        var cleanDest = dest.replace(/^public\//i, "").replace(/^private\//i, "");

        var isSenderPriv = (transferMode === "priv_to_pub" || transferMode === "priv_to_priv");
        var targetFrom = isSenderPriv ? ("Private/" + cleanFrom) : ("Public/" + cleanFrom);

        var isDestPriv = (transferMode === "pub_to_priv" || transferMode === "priv_to_priv");
        var targetDest = cleanDest;
        if (isDestPriv) {
            targetDest = "Private/" + cleanDest;
        } else if (!cleanDest.endsWith(".lez")) {
            targetDest = "Public/" + cleanDest;
        }

        // Ensure internal session has propose permission on sender account
        bridge.invoke("grantAccountAccess", [sessId, cleanFrom, "propose"], function (grantRes) {
            if (selectedAsset === "token" && selectedToken) {
                // Fungible Token Transfer via Token Program (atomic units)
                var tokenAmountRaw = Math.round(amt).toString();
                var fromHolding = selectedToken.holding_id || cleanFrom;
                var toHolding = cleanDest;
                var defId = selectedToken.definition_id || "Def/LOGO_GOVERNANCE_v1";

                bridge.invoke("proposeTokenTransfer", [sessId, fromHolding, toHolding, defId, tokenAmountRaw], function (res) {
                    handleProposalResponseWithRetry(res, cleanFrom, cleanDest, amt, isRetry);
                });
            } else {
                // Native LEZ Transfer (atomic units)
                var amountRaw = Math.round(amt).toString();

                bridge.invoke("proposeNativeTransfer", [sessId, targetFrom, targetDest, amountRaw], function (res) {
                    handleProposalResponseWithRetry(res, cleanFrom, cleanDest, amt, isRetry);
                });
            }
        });
    }

    function handleProposalResponseWithRetry(res, fromAcc, dest, amt, isRetry) {
        if (res && res.error && (res.error.indexOf("Session") !== -1 || res.error.indexOf("session") !== -1) && !isRetry) {
            console.warn("[TransferController] Session rejected by backend. Resetting session and retrying...", res.error);
            bridge.activeSessionId = "";
            executeProposal(fromAcc, dest, amt, true);
            return;
        }

        handleProposalResponse(res);
    }

    function handleProposalResponse(res) {
        if (res && res.ok && res.request_id) {
            var reqId = res.request_id;
            controller.lastRequestId = reqId;

            // Submit approval for internal wallet transfer execution
            bridge.invoke("submitApprovalDecision", [reqId, 1], function (decRes) {
                var pollAttempts = 0;
                var maxAttempts = 240;

                function pollStatus() {
                    bridge.invoke("getRequestStatus", [reqId], function (statusRes) {
                        pollAttempts++;
                        if (statusRes && statusRes.ok) {
                            if (statusRes.status === "submitted" && statusRes.tx_hash) {
                                var finalTx = statusRes.tx_hash;
                                var finalAmt = controller.amountInput;
                                var finalDst = controller.destinationInput;
                                controller.isSubmitting = false;
                                controller.lastTxHash = finalTx;
                                controller.transferSuccess(finalTx, finalAmt, finalDst);
                                controller.amountInput = "";
                                controller.destinationInput = "";
                                accountStore.refreshAccounts();
                                accountStore.refreshTokens();
                                return;
                            }
                            if (statusRes.status === "failed") {
                                controller.isSubmitting = false;
                                controller.transferFailed(statusRes.reason || "Transfer execution failed on chain");
                                return;
                            }
                            if (statusRes.status === "rejected") {
                                controller.isSubmitting = false;
                                controller.transferFailed("Transfer was rejected");
                                return;
                            }
                        }

                        if (pollAttempts < maxAttempts) {
                            proposalStatusTimer.callback = pollStatus;
                            proposalStatusTimer.restart();
                        } else {
                            controller.isSubmitting = false;
                            controller.transferFailed("Transfer timed out waiting for network confirmation");
                            accountStore.refreshAccounts();
                            accountStore.refreshTokens();
                        }
                    });
                }

                proposalStatusTimer.callback = pollStatus;
                proposalStatusTimer.restart();
            });
        } else {
            controller.isSubmitting = false;
            controller.transferFailed(res && res.error ? res.error : "Transfer submission failed");
        }
    }
}
