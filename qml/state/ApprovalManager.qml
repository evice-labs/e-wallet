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
    signal queueUpdated()

    Component.onCompleted: {
        // Pre-seed 4 realistic dApp authorization requests to demonstrate queue & max-3 threshold
        pendingRequests = [
            {
                request_id: "req_1001",
                dapp_name: "LEZ Governance DAO",
                origin: "https://dao.lez.logos.co",
                grant_kind: "GrantKind::Propose",
                effect: "Transfer 25.00 LEZ from active public account to Governance Treasury.",
                fee: "0.0015 LEZ",
                state_diff: "-25.0015 LEZ (Public Account)",
                program: "Public/D7ADNV9oTPsS1qT5swbLsec4SZfsHodvJqkw4QqYGMBV",
                verification_status: "Verified"
            },
            {
                request_id: "req_1002",
                dapp_name: "Logos DEX & Swap Portal",
                origin: "https://dex.lez.logos.co",
                grant_kind: "GrantKind::Read",
                effect: "Connect dApp session and read active account addresses.",
                fee: "0.0005 LEZ",
                state_diff: "Session established",
                program: "Public/8b9F4c2B1a980eF710A889",
                verification_status: "Verified"
            },
            {
                request_id: "req_1003",
                dapp_name: "Logos Names Service (LNS)",
                origin: "https://lns.logos.co",
                grant_kind: "GrantKind::Propose",
                effect: "Register domain 'alice.lez' to active identity commitment.",
                fee: "0.0020 LEZ",
                state_diff: "+1 LNS Record (alice.lez)",
                program: "Public/LNS99x73A0219BB1",
                verification_status: "Verified"
            },
            {
                request_id: "req_1004",
                dapp_name: "Anonymous Voting Pool",
                origin: "https://vote.logos.co",
                grant_kind: "GrantKind::SignAttestation",
                effect: "Sign BIP-340 Schnorr zero-knowledge ballot for Proposal #14.",
                fee: "0.0010 LEZ",
                state_diff: "Ballot Cast (Zero-Knowledge)",
                program: "Public/Vote77a11F099C",
                verification_status: "Verified"
            }
        ];
    }

    function enqueueRequest(req) {
        if (!req) return;
        if (!req.request_id) {
            req.request_id = "req_" + Math.floor(Math.random() * 90000 + 10000);
        }
        var list = pendingRequests.slice();
        list.push(req);
        pendingRequests = list;
        queueUpdated();
    }

    function removeRequest(reqId) {
        if (!reqId) return;
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
        if (!req) return;
        handleIncomingPrompt(req);
    }

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
                verificationStatus = res.simulation.verification_status || "Verified";
            } else {
                simulatedEffect = {
                    effect: prompt.effect || "Proposed smart contract execution or transaction dispatch.",
                    gas_fee: prompt.fee || prompt.gas_fee || "0.001 LEZ",
                    state_diff: prompt.state_diff || "Account state transition pending execution",
                    verification_status: prompt.verification_status || "Verified",
                    program_hash: prompt.program || "0x891ae258f92ca844..."
                };
                verificationStatus = prompt.verification_status || "Verified";
            }
            manager.promptReceived(currentPrompt);
        });
    }

    function approve(reqId) {
        var targetId = reqId || (currentPrompt ? currentPrompt.request_id : null);
        if (!targetId) return;

        bridge.invoke("submitApprovalDecision", [targetId, 1], function(res) {
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
        if (!targetId) return;

        bridge.invoke("submitApprovalDecision", [targetId, 0], function(res) {
            manager.decisionSubmitted(targetId, 0);
            removeRequest(targetId);
            if (currentPrompt && currentPrompt.request_id === targetId) {
                isPromptActive = false;
                currentPrompt = null;
                simulatedEffect = null;
            }
        });
    }

    // Diagnostic/Testing simulator to trigger dApp requests into queue
    function simulateDemoRequest(kind) {
        var demoPool = [
            {
                dapp_name: "LEZ Governance DAO",
                origin: "https://dao.lez.logos.co",
                grant_kind: "GrantKind::Propose",
                effect: "Transfer 25.00 LEZ from active public account to Governance Treasury.",
                fee: "0.0015 LEZ",
                state_diff: "-25.0015 LEZ (Public Account)",
                program: "Public/D7ADNV9oTPsS1qT5swbLsec4SZfsHodvJqkw4QqYGMBV",
                verification_status: "Verified"
            },
            {
                dapp_name: "Logos DEX & Swap Portal",
                origin: "https://dex.lez.logos.co",
                grant_kind: "GrantKind::Read",
                effect: "Connect dApp session and read active account addresses.",
                fee: "0.0005 LEZ",
                state_diff: "Session established",
                program: "Public/8b9F4c2B1a980eF710A889",
                verification_status: "Verified"
            },
            {
                dapp_name: "Logos Names Service (LNS)",
                origin: "https://lns.logos.co",
                grant_kind: "GrantKind::Propose",
                effect: "Register domain 'alice.lez' to active identity commitment.",
                fee: "0.0020 LEZ",
                state_diff: "+1 LNS Record (alice.lez)",
                program: "Public/LNS99x73A0219BB1",
                verification_status: "Verified"
            },
            {
                dapp_name: "Anonymous Voting Pool",
                origin: "https://vote.logos.co",
                grant_kind: "GrantKind::SignAttestation",
                effect: "Sign BIP-340 Schnorr zero-knowledge ballot for Proposal #14.",
                fee: "0.0010 LEZ",
                state_diff: "Ballot Cast (Zero-Knowledge)",
                program: "Public/Vote77a11F099C",
                verification_status: "Verified"
            },
            {
                dapp_name: "Shielded Pool Faucet",
                origin: "https://faucet.lez.logos.co",
                grant_kind: "GrantKind::Propose",
                effect: "Mint and deposit 10.00 testnet shielded LEZ note.",
                fee: "0.0002 LEZ",
                state_diff: "+10.00 LEZ (Shielded Note)",
                program: "Public/ShieldedMint01",
                verification_status: "Verified"
            }
        ];

        var index = Math.floor(Math.random() * demoPool.length);
        var base = demoPool[index];
        var item = {
            request_id: "req_demo_" + Math.floor(Math.random() * 90000 + 10000),
            dapp_name: base.dapp_name,
            origin: base.origin,
            grant_kind: base.grant_kind,
            effect: base.effect,
            fee: base.fee,
            state_diff: base.state_diff,
            program: base.program,
            verification_status: base.verification_status
        };
        enqueueRequest(item);
    }
}
