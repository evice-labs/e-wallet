import QtQuick

Item {
    id: manager

    required property var bridge
    required property var accountStore
    property var ledgerViewRef: null

    GasCalculator {
        id: gasCalc
    }

    property var pendingRequests: []
    property var resolvedRequestIds: ({})
    property var currentPrompt: null
    property var simulatedEffect: null
    property string verificationStatus: "Verified" // "Verified" | "Unverified" | "Untrusted"
    property bool isPromptActive: false
    property bool isSimulating: false
    property bool _isChecking: false

    signal promptReceived(var prompt)
    signal promptDismissed(string requestId)
    signal decisionSubmitted(string requestId, int decision)
    signal queueUpdated

    Component.onCompleted: {
        pendingRequests = [];
        checkPendingApprovals();
    }

    Connections {
        target: manager.bridge
        function onWalletStateChanged() {
            if (manager.bridge && !manager.bridge.isLocked) {
                manager.checkPendingApprovals();
            } else {
                manager.pendingRequests = [];
                manager.isPromptActive = false;
                manager.currentPrompt = null;
                manager.simulatedEffect = null;
            }
        }
    }

    Connections {
        target: Qt.application
        function onStateChanged() {
            if (Qt.application.state === Qt.ApplicationActive && manager.bridge && !manager.bridge.isLocked) {
                manager.checkPendingApprovals();
            }
        }
    }

    Timer {
        id: approvalWatcherTimer
        interval: 1000
        repeat: true
        running: manager.bridge && manager.bridge.isInitialized && !manager.bridge.isLocked
        onTriggered: {
            if (manager.isPromptActive && manager.currentPrompt && manager.currentPrompt.request_id) {
                var activeReqId = manager.currentPrompt.request_id;
                manager.bridge.invoke("getRequestStatus", [activeReqId], function (stRes) {
                    var st = (stRes && stRes.ok && stRes.status) ? String(stRes.status) : "";
                    if ((stRes && stRes.ok === false) || (st && st !== "pending_approval")) {
                        var stalePrompt = manager.currentPrompt;
                        manager._cleanupPromptEnvelope(stalePrompt);
                        manager.removeRequest(activeReqId);
                        if (manager.currentPrompt && manager.currentPrompt.request_id === activeReqId) {
                            manager.isPromptActive = false;
                            manager.currentPrompt = null;
                            manager.simulatedEffect = null;
                        }
                        manager.promptDismissed(activeReqId);
                        manager.checkPendingApprovals();
                    }
                });
            } else {
                manager.checkPendingApprovals();
            }
        }
    }

    function hasRequest(reqId) {
        if (!reqId)
            return false;
        if (resolvedRequestIds[reqId])
            return true;
        if (currentPrompt && currentPrompt.request_id === reqId)
            return true;
        for (var i = 0; i < pendingRequests.length; i++) {
            if (pendingRequests[i].request_id === reqId)
                return true;
        }
        return false;
    }

    function checkPendingApprovals() {
        if (!bridge || !bridge.isInitialized || bridge.isLocked || _isChecking || isPromptActive)
            return;

        _isChecking = true;

        // 1. Check native C++ queue (listPendingApprovals) if supported by the loaded e_wallet_core binary
        bridge.invoke("listPendingApprovals", [], function (res) {
            if (res && res.ok && Array.isArray(res.prompts) && res.prompts.length > 0) {
                _processCandidatePrompts(res.prompts, 0, function () {
                    _checkSessionEnvelopeApprovals();
                });
            } else {
                _checkSessionEnvelopeApprovals();
            }
        });
    }

    function _checkSessionEnvelopeApprovals() {
        bridge.invoke("listSessions", [], function (res) {
            if (!res || !res.ok || !Array.isArray(res.sessions)) {
                _isChecking = false;
                _presentNextIfIdle();
                return;
            }

            var candidates = [];
            for (var i = 0; i < res.sessions.length; i++) {
                var s = res.sessions[i];
                if (s && s.caller_identity && s.caller_identity.startsWith("internal_approval:")) {
                    var rawJson = s.caller_identity.substring("internal_approval:".length);
                    try {
                        var parsed = JSON.parse(rawJson);
                        if (parsed && parsed.request_id) {
                            parsed._envelope_session_id = s.session_id;
                            candidates.push(parsed);
                        }
                    } catch (e)
                    // Ignore malformed envelope
                    {}
                }
            }

            if (candidates.length === 0) {
                _isChecking = false;
                _presentNextIfIdle();
                return;
            }

            _processCandidatePrompts(candidates, 0, function () {
                _isChecking = false;
                _presentNextIfIdle();
            });
        });
    }

    function _processCandidatePrompts(candidates, idx, doneCallback) {
        if (idx >= candidates.length) {
            if (doneCallback)
                doneCallback();
            return;
        }

        var cand = candidates[idx];
        var reqId = cand ? cand.request_id : "";
        if (!reqId) {
            _processCandidatePrompts(candidates, idx + 1, doneCallback);
            return;
        }
        if (hasRequest(reqId)) {
            _mergeEnvelopeMetadata(reqId, cand);
            _processCandidatePrompts(candidates, idx + 1, doneCallback);
            return;
        }

        // Verify with SdkEngine that this request_id is genuinely in pending_approval state
        bridge.invoke("getRequestStatus", [reqId], function (stRes) {
            var st = (stRes && stRes.ok && stRes.status) ? stRes.status : "";
            if (st === "pending_approval") {
                enqueueRequest(cand);
            } else if (cand._envelope_session_id) {
                // Clean up stale envelope for already-resolved/expired request
                bridge.invoke("revokeSession", [cand._envelope_session_id]);
            }
            _processCandidatePrompts(candidates, idx + 1, doneCallback);
        });
    }

    function _presentNextIfIdle() {
        if (!isPromptActive && pendingRequests.length > 0) {
            handleIncomingPrompt(pendingRequests[0]);
        }
    }

    function enqueueRequest(req) {
        if (!req)
            return;
        if (!req.request_id) {
            req.request_id = "req_" + Math.floor(Math.random() * 90000 + 10000);
        }
        if (hasRequest(req.request_id))
            return;
        var list = pendingRequests.slice();
        list.push(req);
        pendingRequests = list;
        queueUpdated();
    }

    function removeRequest(reqId) {
        if (!reqId)
            return;
        var list = [];
        for (var i = 0; i < pendingRequests.length; i++) {
            if (pendingRequests[i].request_id !== reqId) {
                list.push(pendingRequests[i]);
            }
        }
        pendingRequests = list;
        queueUpdated();
    }

    function _mergeEnvelopeMetadata(reqId, env) {
        if (!reqId || !env)
            return;
        var mergeInto = function (target) {
            if (!target)
                return target;
            var merged = Object.assign({}, target);
            if (env._envelope_session_id)
                merged._envelope_session_id = env._envelope_session_id;
            if (env.dapp_name)
                merged.dapp_name = env.dapp_name;
            if (env.program_id)
                merged.program_id = env.program_id;
            if (env.payer_id)
                merged.payer_id = env.payer_id;
            if (env.to)
                merged.to = env.to;
            if (env.amount)
                merged.amount = env.amount;
            if (env.summary && (!merged.summary || merged.summary.indexOf(":") !== -1))
                merged.summary = env.summary;
            if (env.effects && (!merged.effects || merged.effects.indexOf("Decoded(") === 0))
                merged.effects = env.effects;
            return merged;
        };

        if (currentPrompt && currentPrompt.request_id === reqId) {
            currentPrompt = mergeInto(currentPrompt);
        }
        for (var i = 0; i < pendingRequests.length; i++) {
            if (pendingRequests[i].request_id === reqId) {
                var list = pendingRequests.slice();
                list[i] = mergeInto(list[i]);
                pendingRequests = list;
                break;
            }
        }
    }

    function _normalizeVerificationStatus(rawStatus) {
        var s = String(rawStatus || "").toLowerCase();
        if (!s || s === "verified" || (s.indexOf("verified") !== -1 && s.indexOf("unverified") === -1))
            return "Verified";
        if (s.indexOf("untrusted") !== -1)
            return "Untrusted";
        return "Unverified";
    }

    function _cleanEffectText(rawEffect, promptObj) {
        var eff = String(rawEffect || "").trim();
        var decMatch = eff.match(/^Decoded\(([^)]+)\)$/);
        if (decMatch) {
            return "Invoke " + decMatch[1];
        }
        if (!eff || eff.indexOf("Unavailable") !== -1) {
            var prog = (promptObj && (promptObj.program_id || promptObj.program)) ? String(promptObj.program_id || promptObj.program) : "";
            return prog ? ("Invoke Program " + prog.substring(0, 12) + "...") : "Smart Contract Execution";
        }
        return eff;
    }

    function _estimateGasDisplay(promptObj) {
        var rk = (promptObj && promptObj.request_kind) ? String(promptObj.request_kind) : "contract_call";
        if (rk === "native_transfer") {
            var nat = gasCalc.calculateTransferGas("pub_to_pub", false);
            return "~" + nat.displayStr + " units";
        }
        return "~275,640 units";
    }

    function handleIncomingPrompt(prompt) {
        if (!prompt)
            return;
        currentPrompt = prompt;
        isPromptActive = true;
        isSimulating = true;

        var promptJson = typeof prompt === "string" ? prompt : JSON.stringify(prompt);

        bridge.invoke("simulatePromptEffect", [promptJson], function (res) {
            isSimulating = false;
            var summaryText = prompt.summary || "Smart contract execution";
            var sim = (res && res.ok && res.simulation) ? res.simulation : null;
            var rawVer = (sim && sim.verification_status) ? sim.verification_status : (prompt.verification_status || "Verified");
            var normVer = _normalizeVerificationStatus(rawVer);
            var rawStateDiff = (sim && (sim.state_diff || sim.effects)) ? (sim.state_diff || sim.effects) : (prompt.state_diff || prompt.effects || "");

            simulatedEffect = {
                effect: summaryText,
                gas_fee: _estimateGasDisplay(prompt),
                state_diff: _cleanEffectText(rawStateDiff, prompt),
                verification_status: normVer,
                program_hash: prompt.program_id || prompt.program || ""
            };
            verificationStatus = normVer;
            manager.promptReceived(currentPrompt);
        });
    }

    function _cleanupPromptEnvelope(promptObj) {
        if (promptObj && promptObj._envelope_session_id) {
            bridge.invoke("revokeSession", [promptObj._envelope_session_id]);
        }
    }

    function _formatDappDisplayName(promptObj) {
        if (!promptObj)
            return "External dApp";
        var raw = String(promptObj.dapp_name || promptObj.dapp_identity || "").trim();
        if (!raw || raw.toLowerCase() === "unknown")
            return "External dApp";
        if (raw.indexOf("_") !== -1 && raw === raw.toLowerCase()) {
            var parts = raw.split("_");
            var formatted = [];
            for (var i = 0; i < parts.length; i++) {
                var w = parts[i];
                if (!w)
                    continue;
                formatted.push(w.charAt(0).toUpperCase() + w.slice(1));
            }
            return formatted.join(" ");
        }
        return raw;
    }

    function _extractDappAmount(promptObj) {
        if (promptObj && promptObj.amount !== undefined && promptObj.amount !== null) {
            var rawAmt = String(promptObj.amount).trim();
            if (rawAmt !== "" && rawAmt !== "0") {
                return rawAmt;
            }
        }
        return "0";
    }

    Timer {
        id: postApprovalRefreshTimer
        interval: 4000
        repeat: true
        property int tickCount: 0
        onTriggered: {
            tickCount++;
            if (manager.accountStore) {
                manager.accountStore.refreshAccounts();
            }
            if (manager.ledgerViewRef && typeof manager.ledgerViewRef.reconcilePendingTransactions === "function") {
                manager.ledgerViewRef.reconcilePendingTransactions();
            }
            if (tickCount >= 3) {
                stop();
                tickCount = 0;
            }
        }
    }

    Timer {
        id: approvalTxPollTimer
        interval: 500
        repeat: true
        property string targetReqId: ""
        property var targetPrompt: null
        property int attempts: 0

        onTriggered: {
            if (!targetReqId || !manager.bridge) {
                stop();
                return;
            }
            attempts++;
            manager.bridge.invoke("getRequestStatus", [targetReqId], function (statusRes) {
                if (statusRes && statusRes.ok) {
                    var st = String(statusRes.status || "");
                    if ((st === "submitted" || st === "confirmed" || st === "completed") && statusRes.tx_hash) {
                        approvalTxPollTimer.stop();
                        manager._recordApprovedDappActivity(targetPrompt, statusRes.tx_hash);
                        return;
                    }
                    if (st === "failed" || st === "rejected" || st === "cancelled") {
                        approvalTxPollTimer.stop();
                        return;
                    }
                }
                if (approvalTxPollTimer.attempts >= 60) {
                    approvalTxPollTimer.stop();
                }
            });
        }
    }

    function _recordApprovedDappActivity(promptObj, txHash) {
        var dappTitle = _formatDappDisplayName(promptObj);
        var actionAmount = _extractDappAmount(promptObj);
        var fullDetail = (promptObj && promptObj.summary) ? String(promptObj.summary) : "dApp Smart Contract Execution";
        var activeAccId = (accountStore && accountStore.activeAccount && accountStore.activeAccount.account_id) ? accountStore.activeAccount.account_id : "";
        var payerId = (promptObj && (promptObj.payer_id || promptObj.payer)) ? String(promptObj.payer_id || promptObj.payer) : activeAccId;
        var cleanPayerId = String(payerId || "").replace(/^Public\//i, "").replace(/^Private\//i, "");
        var targetContract = (promptObj && (promptObj.program_id || promptObj.program || promptObj.to)) ? String(promptObj.program_id || promptObj.program || promptObj.to) : "";
        var isNativeTransfer = (promptObj && promptObj.request_kind === "native_transfer");
        var routeStr = isNativeTransfer ? "Public ➝ Public" : "Public ➝ zkVM Contract";
        var defaultGas = isNativeTransfer ? "2,968" : "275,640";

        if (ledgerViewRef && typeof ledgerViewRef.addActivity === "function") {
            ledgerViewRef.addActivity(dappTitle, "DAPP", "dApps", actionAmount, fullDetail, false, txHash, defaultGas, "Pending", routeStr, cleanPayerId || activeAccId, "2,000,000", cleanPayerId || activeAccId, targetContract || "zkVM Contract");
        }

        if (accountStore) {
            accountStore.refreshAccounts();
        }
        postApprovalRefreshTimer.tickCount = 0;
        postApprovalRefreshTimer.restart();
    }

    function approve(reqId) {
        var targetId = reqId || (currentPrompt ? currentPrompt.request_id : null);
        if (!targetId)
            return;

        var activePromptObj = currentPrompt ? Object.assign({}, currentPrompt) : null;
        var updatedResolved = Object.assign({}, resolvedRequestIds);
        updatedResolved[targetId] = true;
        resolvedRequestIds = updatedResolved;

        bridge.invoke("submitApprovalDecision", [targetId, 1], function (res) {
            _cleanupPromptEnvelope(activePromptObj);
            manager.decisionSubmitted(targetId, 1);
            removeRequest(targetId);
            if (currentPrompt && currentPrompt.request_id === targetId) {
                isPromptActive = false;
                currentPrompt = null;
                simulatedEffect = null;
            }
            approvalTxPollTimer.stop();
            approvalTxPollTimer.targetReqId = targetId;
            approvalTxPollTimer.targetPrompt = activePromptObj;
            approvalTxPollTimer.attempts = 0;
            approvalTxPollTimer.start();
            _presentNextIfIdle();
        });
    }

    function reject(reqId) {
        var targetId = reqId || (currentPrompt ? currentPrompt.request_id : null);
        if (!targetId)
            return;

        var activePromptObj = currentPrompt;
        var updatedResolved = Object.assign({}, resolvedRequestIds);
        updatedResolved[targetId] = true;
        resolvedRequestIds = updatedResolved;

        bridge.invoke("submitApprovalDecision", [targetId, 0], function (res) {
            _cleanupPromptEnvelope(activePromptObj);
            manager.decisionSubmitted(targetId, 0);
            removeRequest(targetId);
            if (currentPrompt && currentPrompt.request_id === targetId) {
                isPromptActive = false;
                currentPrompt = null;
                simulatedEffect = null;
            }
            _presentNextIfIdle();
        });
    }
}
