import QtQuick

Item {
    id: manager

    required property var bridge
    required property var accountStore

    property var pendingRequests: []
    property var currentPrompt: null
    property var simulatedEffect: null
    property string verificationStatus: "Verified" // "Verified" | "Unverified" | "Untrusted"
    property bool isPromptActive: false
    property bool isSimulating: false

    signal promptReceived(var prompt)
    signal decisionSubmitted(string requestId, int decision)
    signal queueUpdated

    Component.onCompleted: {
        pendingRequests = [];
    }

    function enqueueRequest(req) {
        if (!req)
            return;
        if (!req.request_id) {
            req.request_id = "req_" + Math.floor(Math.random() * 90000 + 10000);
        }
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

    function selectAndReviewRequest(req) {
        if (!req)
            return;
        handleIncomingPrompt(req);
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
            if (res && res.ok && res.simulation) {
                simulatedEffect = res.simulation;
                verificationStatus = res.simulation.verification_status || "Verified";
            } else {
                simulatedEffect = {
                    effect: prompt.effect || "Proposed smart contract execution or transaction dispatch.",
                    gas_fee: prompt.fee || prompt.gas_fee || "0.001 LEZ",
                    state_diff: prompt.state_diff || "Account state transition pending execution",
                    verification_status: prompt.verification_status || "Verified",
                    program_hash: prompt.program || ""
                };
                verificationStatus = prompt.verification_status || "Verified";
            }
            manager.promptReceived(currentPrompt);
        });
    }

    function approve(reqId) {
        var targetId = reqId || (currentPrompt ? currentPrompt.request_id : null);
        if (!targetId)
            return;

        bridge.invoke("submitApprovalDecision", [targetId, 1], function (res) {
            manager.decisionSubmitted(targetId, 1);
            removeRequest(targetId);
            if (currentPrompt && currentPrompt.request_id === targetId) {
                isPromptActive = false;
                currentPrompt = null;
                simulatedEffect = null;
            }
        });
    }

    function reject(reqId) {
        var targetId = reqId || (currentPrompt ? currentPrompt.request_id : null);
        if (!targetId)
            return;

        bridge.invoke("submitApprovalDecision", [targetId, 0], function (res) {
            manager.decisionSubmitted(targetId, 0);
            removeRequest(targetId);
            if (currentPrompt && currentPrompt.request_id === targetId) {
                isPromptActive = false;
                currentPrompt = null;
                simulatedEffect = null;
            }
        });
    }
}
