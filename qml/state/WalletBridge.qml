import QtQuick
import QtCore

Item {
    id: bridge

    readonly property bool isHostAvailable: typeof logos !== "undefined" && typeof logos.callModule === "function"
    property bool isInitialized: false
    property bool isLocked: true

    // Ephemeral internal session handle; invalidated on backend restart or lock
    property string activeSessionId: ""

    property string currentNetwork: "Logos Testnet 0.4"
    property string activeAccountAddress: ""
    property string dataDir: {
        var urlStr = StandardPaths.writableLocation(StandardPaths.GenericDataLocation).toString();
        if (urlStr.startsWith("file://")) {
            urlStr = urlStr.substring(7);
        }
        return urlStr ? (urlStr + "/Logos/module_data/e_wallet_core") : "";
    }

    signal errorOccurred(string method, string message)
    signal walletStateChanged
    signal toastRequested(string message, string level)

    Component.onCompleted: {
        checkStatus();
    }

    function checkStatus() {
        if (!isHostAvailable) {
            console.warn("[WalletBridge] logos.callModule host is not available in standalone execution.");
            bridge.isInitialized = false;
            bridge.isLocked = true;
            bridge.walletStateChanged();
            return;
        }

        invoke("isInitialized", [], function (res) {
            var alreadyInitialized = false;
            if (res) {
                if (res.value === true || res.initialized === true) {
                    alreadyInitialized = true;
                }
            }

            if (alreadyInitialized) {
                fetchSdkInfoAndSession();
            } else {
                // Probe engine instance with persistent storage directory and blank password
                invoke("initEngine", [bridge.dataDir, ""], function (initRes) {
                    if (initRes && initRes.ok) {
                        fetchSdkInfoAndSession();
                    } else {
                        // If initEngine fails with path initialization error, it means an encrypted keystore
                        // already exists on disk (wallet_storage.json) and requires the master password.
                        var errMsg = (initRes && initRes.error) ? String(initRes.error) : "";
                        var isLockedKeystore = errMsg.indexOf("Failed to initialize wallet engine at path") !== -1 || errMsg.indexOf("InvalidPassword") !== -1 || errMsg.indexOf("WALLET_LOCKED") !== -1;

                        if (isLockedKeystore) {
                            console.log("[WalletBridge] Persistent encrypted wallet detected on disk. Presenting lock screen.");
                            bridge.isInitialized = true;
                            bridge.isLocked = true;
                            bridge.walletStateChanged();
                        } else {
                            console.error("[WalletBridge] initEngine failed:", JSON.stringify(initRes));
                            bridge.isInitialized = false;
                            bridge.isLocked = true;
                            bridge.walletStateChanged();
                        }
                    }
                });
            }
        });
    }

    function fetchSdkInfoAndSession() {
        invoke("getSdkInfo", [], function (res) {
            if (res && res.ok) {
                var isInit = (res.wallet_initialized !== undefined) ? !!res.wallet_initialized : (res.initialized !== undefined ? !!res.initialized : false);
                var isLock = (res.wallet_locked !== undefined) ? !!res.wallet_locked : (res.locked !== undefined ? !!res.locked : true);
                bridge.isInitialized = isInit;
                bridge.isLocked = isLock;
                if (res.network) {
                    bridge.currentNetwork = res.network;
                }
                if (bridge.isInitialized && !bridge.isLocked) {
                    ensureActiveSession(function () {
                        bridge.walletStateChanged();
                    });
                } else {
                    bridge.walletStateChanged();
                }
            }
        });
    }

    function ensureActiveSession(callback) {
        if (bridge.activeSessionId && bridge.activeSessionId.length > 0) {
            if (callback)
                callback({
                    ok: true,
                    session_id: bridge.activeSessionId
                });
            return;
        }

        invoke("connectDApp", ["internal_wallet_ui", 1], function (res) {
            if (res && res.ok && res.session_id) {
                bridge.activeSessionId = res.session_id;
                console.log("[WalletBridge] Internal dApp session active:", bridge.activeSessionId);
            } else {
                var errStr = (res && res.error) ? String(res.error) : "";
                if (errStr.indexOf("WalletLocked") !== -1 || errStr.indexOf("locked") !== -1) {
                    bridge.isLocked = true;
                    bridge.activeSessionId = "";
                    bridge.walletStateChanged();
                }
                console.warn("[WalletBridge] connectDApp failed:", JSON.stringify(res));
            }
            if (callback)
                callback(res);
        });
    }

    function parseJsonResult(rawResult) {
        var parsed = rawResult;
        for (var unwrapCount = 0; unwrapCount < 3 && typeof parsed === "string"; unwrapCount++) {
            var trimmed = parsed.trim();
            if ((trimmed.startsWith("{") && trimmed.endsWith("}")) || (trimmed.startsWith("[") && trimmed.endsWith("]")) || (trimmed.startsWith("\"") && trimmed.endsWith("\""))) {
                try {
                    parsed = JSON.parse(trimmed);
                } catch (e) {
                    break;
                }
            } else {
                break;
            }
        }

        if (typeof parsed !== "object" || parsed === null) {
            parsed = {
                ok: true,
                value: parsed
            };
        }
        return parsed;
    }

    // Primary Dispatch Method
    function invoke(method, args, callback) {
        if (!isHostAvailable) {
            var unavailableErr = {
                ok: false,
                error: "Host module 'e_wallet_core' is not available. Ensure application is launched within Logos Basecamp or standalone runner."
            };
            bridge.errorOccurred(method, unavailableErr.error);
            if (callback)
                callback(unavailableErr);
            return unavailableErr;
        }

        try {
            var rawResult = logos.callModule("e_wallet_core", method, args || []);
            var parsed = parseJsonResult(rawResult);

            // Cold-start fallback for unlockWallet:
            // If the host process restarted, the in-memory engine handle is null (m_engine == nullptr).
            // Calling unlockWallet directly will fail with "Wallet engine is not initialized".
            // In that case, decrypt and initialize the engine via initEngine using the supplied master password.
            if (method === "unlockWallet" && parsed && parsed.ok === false) {
                var pass = (args && args.length > 0) ? String(args[0]) : "";
                var initRaw = logos.callModule("e_wallet_core", "initEngine", [bridge.dataDir, pass]);
                var initParsed = parseJsonResult(initRaw);

                if (initParsed && initParsed.ok === true) {
                    // CRITICAL: Now that m_engine is initialized with master password,
                    // call unlockWallet to transition store.locked state to false in memory and on disk
                    var unlockRaw = logos.callModule("e_wallet_core", "unlockWallet", [pass]);
                    var unlockParsed = parseJsonResult(unlockRaw);
                    if (unlockParsed && unlockParsed.ok === true) {
                        parsed = unlockParsed;
                    } else {
                        parsed = {
                            ok: true,
                            message: "Keystore unlocked and engine initialized"
                        };
                    }
                } else {
                    parsed = {
                        ok: false,
                        error: "Incorrect master password or decryption failed"
                    };
                }
            } else if (method === "restoreWallet" && parsed && parsed.ok === false) {
                var newPass = (args && args.length > 1) ? String(args[1]) : "";
                var mnem = (args && args.length > 0) ? String(args[0]) : "";
                var initRawRest = logos.callModule("e_wallet_core", "initEngine", [bridge.dataDir, newPass]);
                var initParsedRest = parseJsonResult(initRawRest);
                if (initParsedRest && initParsedRest.ok === true) {
                    var restRaw = logos.callModule("e_wallet_core", "restoreWallet", [mnem, newPass]);
                    parsed = parseJsonResult(restRaw);
                }
            }

            if (parsed && parsed.ok === false) {
                bridge.errorOccurred(method, parsed.error || "Unknown engine error");
            } else if (parsed && parsed.ok === true) {
                // Synchronize core lifecycle state upon successful key management operations
                if (method === "restoreWallet" || method === "unlockWallet") {
                    bridge.isInitialized = true;
                    bridge.isLocked = false;
                    bridge.ensureActiveSession(function () {
                        bridge.walletStateChanged();
                    });
                } else if (method === "lockWallet") {
                    bridge.isLocked = true;
                    bridge.activeSessionId = "";
                    bridge.walletStateChanged();
                }
            }

            if (callback)
                callback(parsed);
            return parsed;
        } catch (err) {
            var errStr = String(err);
            bridge.errorOccurred(method, errStr);
            var errObj = {
                ok: false,
                error: errStr
            };
            if (callback)
                callback(errObj);
            return errObj;
        }
    }
}
