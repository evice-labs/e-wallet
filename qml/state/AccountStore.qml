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
    }

    property var accounts: []
    property var activeAccount: null
    property string totalPublicBalance: "0.00"
    property string totalShieldedBalance: "0.00"
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
        if (!activeAccount)
            return "Vault";
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
        return name.length > 0 ? name.charAt(0).toUpperCase() : "V";
    }

    function getAccountLabel(acc) {
        if (!acc)
            return "Vault";
        var id = acc.account_id;
        if (id && accountLabels[id])
            return accountLabels[id];
        if (acc.label && String(acc.label).trim().length > 0) {
            return String(acc.label).trim();
        }
        return acc.is_private ? "Shielded Account" : "Public Account";
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

    function refreshAccounts() {
        if (store.isLoading)
            return;
        store.isLoading = true;

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
                    acc.formatted_balance = Number(bal).toFixed(2);

                    // Retain session label if user renamed it in this session
                    if (store.accountLabels[acc.account_id]) {
                        acc.label = store.accountLabels[acc.account_id];
                    }

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
                        kAcc.formatted_balance = Number(kBal).toFixed(2);
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
                store.totalPublicBalance = Number(pubTotal).toFixed(2);
                store.totalShieldedBalance = Number(privTotal).toFixed(2);

                if (!foundActive && processedAccounts.length > 0) {
                    store.activeAccount = processedAccounts[0];
                    if (processedAccounts[0] && processedAccounts[0].account_id) {
                        localSettings.lastActiveAccountId = processedAccounts[0].account_id;
                    }
                } else if (processedAccounts.length === 0) {
                    store.activeAccount = null;
                    localSettings.lastActiveAccountId = "";
                }

                store.accountsUpdated();
            }
        });
    }

    function selectAccount(account) {
        store.activeAccount = account;
        if (account && account.account_id) {
            localSettings.lastActiveAccountId = account.account_id;
        }
        store.accountSelected(account);
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
        store.totalPublicBalance = Number(pubTotal).toFixed(2);
        store.totalShieldedBalance = Number(privTotal).toFixed(2);

        store.accountsUpdated();

        // 5. Notify backend module if method exists
        if (bridge && typeof bridge.invoke === "function") {
            bridge.invoke("deleteAccount", [accountId], function (res) {
            // Non-blocking sync
            });
        }

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

    function refreshTokens() {
        bridge.invoke("listTokenHoldings", [], function (res) {
            if (res && res.ok && Array.isArray(res.tokens)) {
                store.tokens = res.tokens;
                if (!store.selectedToken && res.tokens.length > 0) {
                    store.selectedToken = res.tokens[0];
                }
                store.tokensUpdated();
            }
        });
    }

    function selectToken(token) {
        store.selectedToken = token;
        store.tokensUpdated();
    }
}
