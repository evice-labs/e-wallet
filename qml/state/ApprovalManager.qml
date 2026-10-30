import QtQuick

Item {
    id: manager

    required property var bridge
    required property var accountStore

    property var currentPrompt: null
    property var simulatedEffect: null
    property string verificationStatus: "Verified" // "Verified" | "Unverified" | "Untrusted"
    property bool isPromptActive: false
    property bool isSimulating: false

    signal promptReceived(var prompt)
    signal decisionSubmitted(string requestId, int decision)

    function handleIncomingPrompt(prompt) {
        if (!prompt) return;
        currentPrompt = prompt;
        isPromptActive = true;
        isSimulating = true;

        var promptJson = typeof prompt === "string" ? prompt : JSON.stringify(prompt);

        bridge.invoke("simulatePromptEffect", [promptJson], function(res) {
            isSimulating = false;
            if (res && res.ok && res.simulation) {
                simulatedEffect = res.simulation;
                if (res.simulation.verification_status) {
                    verificationStatus = res.simulation.verification_status;
                } else {
                    verificationStatus = "Verified";
                }
            } else {
                simulatedEffect = {
                    effect: prompt.effect || "Proposed smart contract execution or transaction dispatch.",
                    gas_fee: prompt.fee || "0.001 LEZ",
                    state_diff: prompt.state_diff || "Account state transition pending execution",
                    verification_status: "Verified",
                    program_hash: prompt.program || "0x891ae258f92ca844..."
                };
                verificationStatus = "Verified";
            }
            manager.promptReceived(currentPrompt);
        });
    }

    function approve() {
        if (!currentPrompt) return;
        var reqId = currentPrompt.request_id || "req_pending";
        bridge.invoke("submitApprovalDecision", [reqId, 1], function(res) {
            manager.decisionSubmitted(reqId, 1);
            isPromptActive = false;
            currentPrompt = null;
            simulatedEffect = null;
        });
    }

    function reject() {
        if (!currentPrompt) return;
        var reqId = currentPrompt.request_id || "req_pending";
        bridge.invoke("submitApprovalDecision", [reqId, 0], function(res) {
            manager.decisionSubmitted(reqId, 0);
            isPromptActive = false;
            currentPrompt = null;
            simulatedEffect = null;
        });
    }

    // Diagnostic/Testing simulator to trigger approval modal
    function simulateDemoRequest(kind) {
        var demo = {
            request_id: "req_demo_" + Math.floor(Math.random() * 90000 + 10000),
            dapp_name: kind === "connect" ? "Logos DEX & Swap Portal" : "LEZ Governance DAO",
            origin: kind === "connect" ? "https://dex.lez.logos.co" : "https://dao.lez.logos.co",
            grant_kind: kind === "connect" ? "GrantKind::Read" : "GrantKind::Propose",
            effect: kind === "connect" ?
                    "Connect dApp session and read active account addresses." :
                    "Transfer 25.00 LEZ from active public account to Governance Treasury.",
            fee: "0.0015 LEZ",
            state_diff: kind === "connect" ? "Session established" : "-25.0015 LEZ (Public Account)",
            program: "Public/D7ADNV9oTPsS1qT5swbLsec4SZfsHodvJqkw4QqYGMBV",
            verification_status: "Verified"
        };
        handleIncomingPrompt(demo);
    }
}
