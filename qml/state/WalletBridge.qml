import QtQuick

Item {
    id: bridge

    readonly property bool isHostAvailable: typeof logos !== "undefined" && typeof logos.callModule === "function"
    property bool isInitialized: true
    property bool isLocked: false
    property string activeSessionId: "sess_local_standalone"
    property string currentNetwork: "Logos Testnet 0.4"
    property string activeAccountAddress: ""

    signal errorOccurred(string method, string message)
    signal walletStateChanged()
    signal toastRequested(string message, string level)

    Component.onCompleted: {
        checkStatus();
    }

    function checkStatus() {
        invoke("isInitialized", [], function(res) {
            if (res && res.ok) {
                bridge.isInitialized = !!res.initialized;
            }
        });
        invoke("getSdkInfo", [], function(res) {
            if (res && res.ok && res.network) {
                bridge.currentNetwork = res.network;
            }
        });
    }

    // Primary Dispatch Method
    function invoke(method, args, callback) {
        if (!isHostAvailable) {
            // Standalone Mock Harness for Preview & Development
            var mockResponse = mockDispatch(method, args);
            if (callback) callback(mockResponse);
            return mockResponse;
        }

        try {
            var rawResult = logos.callModule("e_wallet_core", method, args || []);
            var parsed = null;
            if (typeof rawResult === "string") {
                try {
                    parsed = JSON.parse(rawResult);
                } catch (e) {
                    parsed = { ok: true, raw: rawResult };
                }
            } else if (typeof rawResult === "object") {
                parsed = rawResult;
            } else {
                parsed = { ok: true, value: rawResult };
            }

            if (parsed && parsed.ok === false) {
                bridge.errorOccurred(method, parsed.error || "Unknown engine error");
            }

            if (callback) callback(parsed);
            return parsed;
        } catch (err) {
            var errStr = String(err);
            bridge.errorOccurred(method, errStr);
            var errObj = { ok: false, error: errStr };
            if (callback) callback(errObj);
            return errObj;
        }
    }

    // Standalone Fallback / Mock Engine
    function mockDispatch(method, args) {
        switch (method) {
            case "isInitialized":
                return { ok: true, initialized: bridge.isInitialized };
            case "getSdkInfo":
                return { ok: true, version: "0.1.1", network: "Logos Testnet 0.4", engine: "mock-preview" };
            case "createWallet":
                bridge.isInitialized = true;
                bridge.isLocked = false;
                bridge.walletStateChanged();
                return {
                    ok: true,
                    mnemonic: "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about"
                };
            case "restoreWallet":
                bridge.isInitialized = true;
                bridge.isLocked = false;
                bridge.walletStateChanged();
                return { ok: true, restored: true };
            case "unlockWallet":
                bridge.isLocked = false;
                bridge.walletStateChanged();
                return { ok: true, unlocked: true };
            case "lockWallet":
                bridge.isLocked = true;
                bridge.walletStateChanged();
                return { ok: true, locked: true };
            case "createPublicAccount":
                var pubLabel = (args && args[0]) ? args[0] : "Public Account";
                return {
                    ok: true,
                    account_id: "Public/891ae258f92ca8447af6cf09c41d96b3a06187d098b91ab2cc17b42e3c4a2fa1",
                    label: pubLabel,
                    is_private: false
                };
            case "createPrivateAccount":
                var privLabel = (args && args[0]) ? args[0] : "Shielded Account";
                return {
                    ok: true,
                    account_id: "Private/047f3b89e210ac55219e88b2091fa47289b0221948ba90c1f20084ab7199201a",
                    label: privLabel,
                    is_private: true
                };
            case "listAllAccounts":
                return {
                    ok: true,
                    accounts: [
                        {
                            account_id: "Public/891ae258f92ca8447af6cf09c41d96b3a06187d098b91ab2cc17b42e3c4a2fa1",
                            label: "Primary Vault (Public)",
                            is_private: false,
                            balance: "12500000000",
                            formatted_balance: "12,500.00"
                        },
                        {
                            account_id: "Private/047f3b89e210ac55219e88b2091fa47289b0221948ba90c1f20084ab7199201a",
                            label: "Stealth Stash (Shielded)",
                            is_private: true,
                            balance: "8400000000",
                            formatted_balance: "8,400.00"
                        }
                    ]
                };
            case "getBalance":
                return { ok: true, balance: "12500000000", formatted: "12,500.00" };
            case "setAccountLabel":
                return { ok: true, updated: true };
            case "resolveName":
                var name = args && args[1] ? args[1] : "";
                if (name === "alice.lez") {
                    return {
                        ok: true,
                        name: "alice.lez",
                        account_id: "Public/891ae258f92ca8447af6cf09c41d96b3a06187d098b91ab2cc17b42e3c4a2fa1",
                        resolved: true
                    };
                } else if (name === "bob.lez") {
                    return {
                        ok: true,
                        name: "bob.lez",
                        account_id: "Public/11223344556677889900aabbccddeeff00112233445566778899aabbccddeeff",
                        resolved: true
                    };
                } else if (name === "stealth.lez" || name === "charlie.lez") {
                    return {
                        ok: true,
                        name: name,
                        account_id: "Private/047f3b89e210ac55219e88b2091fa47289b0221948ba90c1f20084ab7199201a",
                        resolved: true
                    };
                }
                return { ok: false, error: "Name '" + name + "' not registered in LNS" };
            case "proposeNativeTransfer":
                return { ok: true, request_id: "req_mock_98214", status: "pending_approval" };
            case "proposeTokenTransfer":
                return { ok: true, request_id: "req_mock_tok_4412", status: "pending_approval" };
            case "getRequestStatus":
                var reqId = (args && args[0]) ? args[0] : "req_mock_98214";
                return {
                    ok: true,
                    request_id: reqId,
                    status: "submitted",
                    tx_hash: "0x8f3c2b1a9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b3a210987654321fedcba0987"
                };
            case "requestFaucet":
                return {
                    ok: true,
                    amount: "100.00",
                    tx_hash: "0x3f9e8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f"
                };
            case "proposeTransaction":
                return {
                    ok: true,
                    tx_hash: "0x9f538361b55c890f9bd5dae00cf98d4bb677cc3bd129c0147fbe4b23fccaf184",
                    program: (args && args[0]) ? args[0] : "Public/D7ADNV9oTPsS1qT5swbLsec4SZfsHodvJqkw4QqYGMBV",
                    block: 43466,
                    submission_id: (args && args[2]) ? args[2] : "4f793e86-5a23-4d20-969b-b993291caf59"
                };
            case "listTokenHoldings":
                return {
                    ok: true,
                    tokens: [
                        {
                            holding_id: "Holding/01a8b9c7d6e5f4",
                            definition_id: "Def/LOGO_GOVERNANCE_v1",
                            symbol: "LOGO",
                            name: "Logos Governance Token",
                            balance: "2500000000",
                            formatted_balance: "2,500.00",
                            is_shielded: false
                        },
                        {
                            holding_id: "Holding/02c3d4e5f6a7b8",
                            definition_id: "Def/USDL_SHIELDED_STABLE",
                            symbol: "USDL",
                            name: "LEZ Shielded Dollar",
                            balance: "5000000000",
                            formatted_balance: "5,000.00",
                            is_shielded: true
                        }
                    ]
                };
            case "channelDeposit":
                var depAmount = (args && args[1]) ? args[1] : "142.50";
                return {
                    ok: true,
                    amount: depAmount,
                    tx_hash: "0x7c9a1b2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b",
                    recipient: (args && args[0]) ? args[0] : ""
                };
            case "simulatePromptEffect":
                return {
                    ok: true,
                    simulation: {
                        effect: "Transfer 25.00 LEZ from active public account to Governance Treasury.",
                        gas_fee: "0.0015 LEZ",
                        state_diff: "-25.0015 LEZ (Public Account)",
                        verification_status: "Verified",
                        program_hash: "0x891ae258f92ca8447af6cf09c41d96b3a06187d098b91ab2cc17b42e3c4a2fa1"
                    }
                };
            case "submitApprovalDecision":
                return { ok: true, submitted: true, decision: (args && args[1]) ? args[1] : 1 };
            case "getIdentityCommitment":
                return {
                    ok: true,
                    commitment: "0x3f9e8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f",
                    scope_prefix: "lez_id_v1"
                };
            case "deriveScopedNullifier":
                var scope = (args && args[1]) ? args[1] : "governance.logos.co";
                return {
                    ok: true,
                    scope: scope,
                    nullifier: "0x7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b"
                };
            case "signIdentityAttestation":
                return {
                    ok: true,
                    signature: "0xbeef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef",
                    scheme: "BIP-340 Schnorr"
                };
            case "listSessions":
                return { ok: true, sessions: [] };
            default:
                return { ok: true, method: method, message: "Mock execution successful" };
        }
    }
}
