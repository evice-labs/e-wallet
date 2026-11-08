import QtQuick
import QtCore

Item {
    id: store

    required property var bridge

    Settings {
        id: localSettings
        category: "LogosEWalletAccountLabels"
        property string labelsJson: "{}"
        property string deletedAccountsJson: "[]"
        property string lastActiveAccountId: ""
        property string lastKnownBalancesJson: "{}"
    }

    signal depositDetected(string accountLabel, string amount, string accountId, bool isPrivate)
    signal balanceChanged(string accountId, real oldBalance, real newBalance)

    function formatThousands(val) {
        var num = Number(val);
        if (isNaN(num))
            return "0";
        if (Number.isInteger(num)) {
            return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        }
        var parts = num.toFixed(2).split(".");
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        return parts.join(".");
    }

    property var accounts: []
    property var activeAccount: null
    property string totalPublicBalance: "0.00"
    property string totalShieldedBalance: "0.00"
    property bool isReady: false

    readonly property string activePublicBalance: {
        if (!activeAccount)
            return (store.isLoading || !store.isReady) ? "..." : "0.00";
        var isPriv = (activeAccount.is_private === true) || (activeAccount.privacy === "private");
        if (isPriv)
            return "0.00";
        return activeAccount.formatted_balance || store.formatThousands(activeAccount.balance || 0);
    }

    readonly property string activeShieldedBalance: {
        if (!activeAccount)
            return (store.isLoading || !store.isReady) ? "..." : "0.00";
        var isPriv = (activeAccount.is_private === true) || (activeAccount.privacy === "private");
        if (!isPriv)
            return "0.00";
        if (activeAccount.shielded_balance !== undefined && activeAccount.shielded_balance !== null) {
            return store.formatThousands(activeAccount.shielded_balance);
        }
        return activeAccount.formatted_balance || store.formatThousands(activeAccount.balance || 0);
    }

    readonly property string activeTotalBalance: {
        if (!activeAccount)
            return (store.isLoading || !store.isReady) ? "..." : "0.00";
        var pub = parseFloat(String(activePublicBalance).replace(/,/g, "")) || 0;
        var priv = parseFloat(String(activeShieldedBalance).replace(/,/g, "")) || 0;
        return store.formatThousands(pub + priv);
    }

    property var tokens: []
    property string selectedAssetType: "native" // "native" | "token"
    property var selectedToken: null
    property bool isLoading: false

    property var accountLabels: {
        try {
            return JSON.parse(localSettings.labelsJson) || {};
        } catch (e) {
            return {};
        }
    }

    property var deletedAccounts: {
        try {
            return JSON.parse(localSettings.deletedAccountsJson) || [];
        } catch (e) {
            return [];
        }
    }

    readonly property string activeAccountName: {
        if (!activeAccount) {
            if (bridge.isLocked)
                return "Vault Locked";
            if (store.isLoading || !store.isReady)
                return "...";
            return "No Account";
        }
        var id = activeAccount.account_id;
        if (id && accountLabels[id])
            return accountLabels[id];
        if (activeAccount.label && String(activeAccount.label).trim().length > 0) {
            return String(activeAccount.label).trim();
        }
        return activeAccount.is_private ? "Shielded Account" : "Public Account";
    }

    readonly property string activeAccountInitial: {
        var name = activeAccountName;
        return (name.length > 0 && name !== "...") ? name.charAt(0).toUpperCase() : "•";
    }

    function getAccountLabel(target) {
        if (!target)
            return "...";
        var id = typeof target === "string" ? target : target.account_id;
        if (!id)
            return "...";
        if (accountLabels[id])
            return accountLabels[id];
        if (typeof target === "object") {
            if (target.label && String(target.label).trim().length > 0)
                return String(target.label).trim();
            return target.is_private ? "Shielded Account" : "Public Account";
        }
        if (accounts && accounts.length > 0) {
            for (var i = 0; i < accounts.length; i++) {
                if (accounts[i].account_id === id)
                    return getAccountLabel(accounts[i]);
            }
        }
        return id.length > 12 ? (id.substring(0, 6) + "..." + id.substring(id.length - 4)) : id;
    }

    // Event Trigger: Refresh state when application window gains focus / becomes active
    property real lastRefreshTime: 0

    Connections {
        target: Qt.application
        function onStateChanged() {
            if (Qt.application.state === Qt.ApplicationActive && bridge.isInitialized && !bridge.isLocked) {
                var now = Date.now();
                if (now - store.lastRefreshTime > 30000) {
                    store.lastRefreshTime = now;
                    store.refreshAccounts();
                    store.refreshTokens();
                }
            }
        }
    }

    signal accountSelected(var account)
    signal accountsUpdated
    signal tokensUpdated

    Connections {
        target: bridge
        function onWalletStateChanged() {
            if (!bridge.isLocked) {
                store.refreshAccounts();
                store.refreshTokens();
            } else {
                store.isReady = false;
                store.accounts = [];
                store.activeAccount = null;
                store.tokens = [];
                store.selectedToken = null;
                store.totalPublicBalance = "0.00";
                store.totalShieldedBalance = "0.00";
                store.accountsUpdated();
                store.tokensUpdated();
            }
        }
    }

    Component.onCompleted: {
        if (!bridge.isLocked) {
            refreshAccounts();
            refreshTokens();
        }
    }

    property var _refreshCallbacks: []

    function refreshAccounts(callback) {
        if (callback) {
            _refreshCallbacks.push(callback);
        }
        if (store.isLoading) {
            return;
        }
        store.isLoading = true;
        store.lastRefreshTime = Date.now();

        bridge.invoke("listAllAccounts", [], function (res) {
            store.isLoading = false;
            console.log("[AccountStore] listAllAccounts response:", JSON.stringify(res));
            if (res && res.ok && Array.isArray(res.accounts)) {
                var processedAccounts = [];
                var pubTotal = 0;
                var privTotal = 0;
                var foundActive = false;
                var delList = Array.isArray(store.deletedAccounts) ? store.deletedAccounts : [];
                var targetActiveId = (store.activeAccount && store.activeAccount.account_id) ? store.activeAccount.account_id : localSettings.lastActiveAccountId;

                var lastKnown = {};
                try {
                    lastKnown = JSON.parse(localSettings.lastKnownBalancesJson) || {};
                } catch (e) {
                    lastKnown = {};
                }
                var updatedKnown = {};

                for (var i = 0; i < res.accounts.length; i++) {
                    var acc = res.accounts[i];

                    // Skip accounts marked as deleted
                    if (delList.indexOf(acc.account_id) !== -1) {
                        continue;
                    }

                    var isPriv = (acc.privacy === "private") || (acc.is_private === true);
                    var bal = parseFloat(acc.balance || acc.formatted_balance || "0") || 0;
                    acc.is_private = isPriv;
                    acc.address = acc.account_id;
                    acc.canonical_address = acc.canonical_address || (isPriv ? ("Private/" + acc.account_id) : ("Public/" + acc.account_id));
                    acc.formatted_balance = store.formatThousands(bal);

                    // Retain session label if user renamed it in this session
                    if (store.accountLabels[acc.account_id]) {
                        acc.label = store.accountLabels[acc.account_id];
                    }

                    // Balance change & inbound deposit detection
                    var prevBal = lastKnown[acc.account_id];
                    if (prevBal !== undefined && bal !== prevBal) {
                        store.balanceChanged(acc.account_id, prevBal, bal);
                        if (bal > prevBal) {
                            var diff = bal - prevBal;
                            console.log("[AccountStore] Inbound deposit detected for account", acc.account_id, "amount:", diff);
                            store.depositDetected(store.getAccountLabel(acc), store.formatThousands(diff), acc.account_id, isPriv);
                        }
                    }
                    updatedKnown[acc.account_id] = bal;

                    if (isPriv) {
                        privTotal += bal;
                    } else {
                        pubTotal += bal;
                    }

                    processedAccounts.push(acc);

                    if (targetActiveId && targetActiveId === acc.account_id) {
                        store.activeAccount = acc;
                        foundActive = true;
                    }
                }

                // If this is first initialization and no lastKnown records existed, record baseline deposits
                if (Object.keys(lastKnown).length === 0) {
                    for (var d = 0; d < processedAccounts.length; d++) {
                        var dAcc = processedAccounts[d];
                        var dBal = parseFloat(dAcc.balance || dAcc.formatted_balance || "0") || 0;
                        if (dBal > 0) {
                            console.log("[AccountStore] Initial balance deposit recorded for account", dAcc.account_id, "amount:", dBal);
                            store.depositDetected(store.getAccountLabel(dAcc), store.formatThousands(dBal), dAcc.account_id, dAcc.is_private);
                        }
                    }
                }

                try {
                    localSettings.lastKnownBalancesJson = JSON.stringify(updatedKnown);
                } catch (e) {
                    console.warn("[AccountStore] Failed to save lastKnownBalancesJson:", e);
                }

                // Safety check: if all accounts in keystore were filtered by deletedAccounts,
                // recover gracefully by showing all accounts and resetting deletedAccounts list
                if (processedAccounts.length === 0 && res.accounts.length > 0) {
                    store.deletedAccounts = [];
                    localSettings.deletedAccountsJson = "[]";
                    for (var k = 0; k < res.accounts.length; k++) {
                        var kAcc = res.accounts[k];
                        var kIsPriv = (kAcc.privacy === "private") || (kAcc.is_private === true);
                        var kBal = parseFloat(kAcc.balance || kAcc.formatted_balance || "0") || 0;
                        kAcc.is_private = kIsPriv;
                        kAcc.address = kAcc.account_id;
                        kAcc.canonical_address = kAcc.canonical_address || (kIsPriv ? ("Private/" + kAcc.account_id) : ("Public/" + kAcc.account_id));
                        kAcc.formatted_balance = store.formatThousands(kBal);
                        if (store.accountLabels[kAcc.account_id]) {
                            kAcc.label = store.accountLabels[kAcc.account_id];
                        }
                        if (kIsPriv)
                            privTotal += kBal;
                        else
                            pubTotal += kBal;
                        processedAccounts.push(kAcc);
                    }
                }

                store.accounts = processedAccounts;
                store.totalPublicBalance = store.formatThousands(pubTotal);
                store.totalShieldedBalance = store.formatThousands(privTotal);

                if (!foundActive && processedAccounts.length > 0) {
                    store.activeAccount = processedAccounts[0];
                    if (processedAccounts[0] && processedAccounts[0].account_id) {
                        localSettings.lastActiveAccountId = processedAccounts[0].account_id;
                    }
                } else if (processedAccounts.length === 0) {
                    store.activeAccount = null;
                    localSettings.lastActiveAccountId = "";
                }

                if (bridge.activeSessionId && bridge.activeSessionId.length > 0) {
                    for (var g = 0; g < processedAccounts.length; g++) {
                        (function (targetAcc) {
                                bridge.invoke("getBalance", [bridge.activeSessionId, targetAcc.account_id], function (balRes) {
                                    if (balRes && balRes.ok && balRes.balance !== undefined && balRes.balance !== null) {
                                        var nBal = parseFloat(balRes.balance) || 0;
                                        targetAcc.balance = balRes.balance;
                                        targetAcc.formatted_balance = store.formatThousands(nBal);
                                        if (store.activeAccount && store.activeAccount.account_id === targetAcc.account_id) {
                                            var updatedActive = Object.assign({}, store.activeAccount);
                                            updatedActive.balance = balRes.balance;
                                            updatedActive.formatted_balance = store.formatThousands(nBal);
                                            store.activeAccount = updatedActive;
                                        }
                                        store.recalculateTotals();
                                        store.accountsUpdated();
                                    }
                                });
                            })(processedAccounts[g]);
                    }
                }

                store.isReady = true;
                store.accountsUpdated();
            } else {
                store.isReady = true;
                store.accountsUpdated();
            }
            var cbs = _refreshCallbacks.slice();
            _refreshCallbacks = [];
            for (var c = 0; c < cbs.length; c++) {
                try {
                    cbs[c](res);
                } catch (e) {
                    console.error("[AccountStore] refreshAccounts callback error:", e);
                }
            }
        });
    }

    function recalculateTotals() {
        var pubTotal = 0;
        var privTotal = 0;
        for (var i = 0; i < store.accounts.length; i++) {
            var a = store.accounts[i];
            var bal = parseFloat(a.balance || (a.formatted_balance ? String(a.formatted_balance).replace(/,/g, "") : "0")) || 0;
            if (a.is_private || a.privacy === "private") {
                privTotal += bal;
            } else {
                pubTotal += bal;
            }
        }
        store.totalPublicBalance = store.formatThousands(pubTotal);
        store.totalShieldedBalance = store.formatThousands(privTotal);
    }

    function selectAccount(account) {
        store.activeAccount = account;
        if (account && account.account_id) {
            localSettings.lastActiveAccountId = account.account_id;
            refreshActiveAccountBalance();
        }
        store.accountSelected(account);
    }

    function refreshActiveAccountBalance() {
        if (!store.activeAccount || !bridge.activeSessionId)
            return;
        var targetId = store.activeAccount.account_id;
        bridge.invoke("grantAccountAccess", [bridge.activeSessionId, targetId, "read"], function () {
            bridge.invoke("getBalance", [bridge.activeSessionId, targetId], function (balRes) {
                if (balRes && balRes.ok && balRes.balance !== undefined && balRes.balance !== null) {
                    var nBal = parseFloat(balRes.balance) || 0;
                    if (store.activeAccount && store.activeAccount.account_id === targetId) {
                        var updated = Object.assign({}, store.activeAccount);
                        updated.balance = balRes.balance;
                        updated.formatted_balance = store.formatThousands(nBal);
                        store.activeAccount = updated;
                        store.accountsUpdated();
                    }
                }
            });
        });
    }

    function canDeleteAccount(acc) {
        if (!acc || !store.accounts || store.accounts.length <= 1)
            return false;
        return true;
    }

    function deleteAccount(accountId, callback) {
        if (!accountId) {
            if (callback)
                callback({
                    ok: false,
                    error: "Invalid account ID"
                });
            return;
        }
        if (store.accounts.length <= 1) {
            if (callback)
                callback({
                    ok: false,
                    error: "Cannot delete the only account in your wallet. At least one account is required."
                });
            return;
        }

        // 1. Record in persistent deleted accounts list
        var list = Array.isArray(store.deletedAccounts) ? store.deletedAccounts.slice() : [];
        if (list.indexOf(accountId) === -1) {
            list.push(accountId);
        }
        localSettings.deletedAccountsJson = JSON.stringify(list);
        store.deletedAccounts = list;

        // 2. Remove from custom label map
        var labels = Object.assign({}, store.accountLabels);
        if (labels[accountId]) {
            delete labels[accountId];
            localSettings.labelsJson = JSON.stringify(labels);
            store.accountLabels = labels;
        }

        // 3. Immediately update activeAccount and accounts array
        var remaining = [];
        var nextActive = null;
        for (var i = 0; i < store.accounts.length; i++) {
            var a = store.accounts[i];
            if (a.account_id !== accountId) {
                remaining.push(a);
                if (!nextActive) {
                    nextActive = a;
                }
            }
        }

        store.accounts = remaining;
        if (store.activeAccount && store.activeAccount.account_id === accountId) {
            store.activeAccount = nextActive;
            localSettings.lastActiveAccountId = nextActive ? nextActive.account_id : "";
            store.accountSelected(nextActive);
        }

        // 4. Recalculate totals
        var pubTotal = 0;
        var privTotal = 0;
        for (var j = 0; j < remaining.length; j++) {
            var bal = parseFloat(remaining[j].balance || remaining[j].formatted_balance || "0") || 0;
            if (remaining[j].is_private) {
                privTotal += bal;
            } else {
                pubTotal += bal;
            }
        }
        store.totalPublicBalance = store.formatThousands(pubTotal);
        store.totalShieldedBalance = store.formatThousands(privTotal);

        store.accountsUpdated();

        if (callback)
            callback({
                ok: true
            });
    }

    function createAccount(label, isPrivate, callback) {
        var method = isPrivate ? "createPrivateAccount" : "createPublicAccount";
        var defaultLabel = isPrivate ? "Shielded Account" : "Public Account";
        var finalLabel = label && label.trim().length > 0 ? label.trim() : defaultLabel;
        bridge.invoke(method, [finalLabel], function (res) {
            if (res && res.ok && res.account_id) {
                var labels = Object.assign({}, store.accountLabels);
                labels[res.account_id] = finalLabel;
                localSettings.labelsJson = JSON.stringify(labels);
                store.accountLabels = labels;

                // Unmark if previously marked as deleted
                if (Array.isArray(store.deletedAccounts) && store.deletedAccounts.indexOf(res.account_id) !== -1) {
                    var updatedDel = store.deletedAccounts.filter(function (id) {
                        return id !== res.account_id;
                    });
                    localSettings.deletedAccountsJson = JSON.stringify(updatedDel);
                    store.deletedAccounts = updatedDel;
                }

                if (bridge.activeSessionId) {
                    bridge.invoke("grantAccountAccess", [bridge.activeSessionId, res.account_id, "propose"]);
                    bridge.invoke("grantAccountAccess", [bridge.activeSessionId, res.account_id, "read"]);
                }
            }
            store.refreshAccounts();
            if (callback)
                callback(res);
        });
    }

    function setAccountLabel(accountId, label, isPrivate, callback) {
        var trimmed = label ? label.trim() : "";
        if (!trimmed)
            return;

        // 1. Optimistically store in session label map and persist to disk via Settings
        var labels = Object.assign({}, store.accountLabels);
        labels[accountId] = trimmed;
        localSettings.labelsJson = JSON.stringify(labels);
        store.accountLabels = labels;

        // 2. Immediately update activeAccount
        if (store.activeAccount && store.activeAccount.account_id === accountId) {
            var updatedActive = Object.assign({}, store.activeAccount);
            updatedActive.label = trimmed;
            store.activeAccount = updatedActive;
        }

        // 3. Immediately update in accounts array
        var updatedAccounts = [];
        for (var i = 0; i < store.accounts.length; i++) {
            var a = Object.assign({}, store.accounts[i]);
            if (a.account_id === accountId) {
                a.label = trimmed;
            }
            updatedAccounts.push(a);
        }
        store.accounts = updatedAccounts;
        store.accountsUpdated();

        // 4. Send down to core backend for keystore persistence
        bridge.invoke("setAccountLabel", [accountId, trimmed, !!isPrivate], function (res) {
            store.refreshAccounts();
            if (callback)
                callback(res);
        });
    }

    property var _tokenCallbacks: []

    function refreshTokens(callback) {
        if (callback) {
            _tokenCallbacks.push(callback);
        }
        var sid = bridge.activeSessionId || "";
        var method = sid ? "listTokenHoldings" : "listAllTokenHoldings";
        var args = sid ? [sid] : [];
        bridge.invoke(method, args, function (res) {
            var rawList = (res && res.ok && Array.isArray(res.data)) ? res.data : ((res && res.ok && Array.isArray(res.tokens)) ? res.tokens : []);
            store.tokens = rawList;
            if (!store.selectedToken && rawList.length > 0) {
                store.selectedToken = rawList[0];
            }
            store.tokensUpdated();
            var cbs = _tokenCallbacks.slice();
            _tokenCallbacks = [];
            for (var c = 0; c < cbs.length; c++) {
                try {
                    cbs[c](res);
                } catch (e) {
                    console.error("[AccountStore] refreshTokens callback error:", e);
                }
            }
        });
    }

    function selectToken(token) {
        store.selectedToken = token;
        store.tokensUpdated();
    }

    function registerTokenHolding(holdingId, definitionId, symbol, name, isShielded, callback) {
        bridge.invoke("registerTokenHolding", [holdingId, definitionId, symbol, name, !!isShielded], function (res) {
            console.log("[AccountStore] registerTokenHolding result:", JSON.stringify(res));
            store.refreshTokens();
            if (callback)
                callback(res);
        });
    }
}
