import QtQuick

Item {
    id: bridge

    readonly property bool isHostAvailable: typeof logos !== "undefined" && typeof logos.callModule === "function"
    property bool isInitialized: false
    property bool isLocked: true
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
                }
                return { ok: false, error: "Name '" + name + "' not registered in LNS" };
            case "proposeNativeTransfer":
                return { ok: true, request_id: "req_mock_98214", status: "pending_approval" };
            case "proposeTokenTransfer":
                return { ok: true, request_id: "req_mock_tok_4412", status: "pending_approval" };
            case "listSessions":
                return { ok: true, sessions: [] };
            default:
                return { ok: true, method: method, message: "Mock execution successful" };
        }
    }
}
