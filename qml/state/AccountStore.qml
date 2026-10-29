import QtQuick

Item {
    id: store

    required property var bridge

    property var accounts: []
    property var activeAccount: null
    property string totalPublicBalance: "0.00"
    property string totalShieldedBalance: "0.00"
    property var tokens: []
    property string selectedAssetType: "native" // "native" | "token"
    property var selectedToken: null
    property bool isLoading: false

    signal accountSelected(var account)
    signal accountsUpdated()
    signal tokensUpdated()

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
        if (store.isLoading) return;
        store.isLoading = true;

        bridge.invoke("listAllAccounts", [], function(res) {
            store.isLoading = false;
            if (res && res.ok && Array.isArray(res.accounts)) {
                store.accounts = res.accounts;

                var pubTotal = 0;
                var privTotal = 0;
                var foundActive = false;

                for (var i = 0; i < res.accounts.length; i++) {
                    var acc = res.accounts[i];
                    var bal = parseFloat(acc.formatted_balance || "0") || 0;
                    if (acc.is_private) {
                        privTotal += bal;
                    } else {
                        pubTotal += bal;
                    }

                    if (store.activeAccount && store.activeAccount.account_id === acc.account_id) {
                        store.activeAccount = acc;
                        foundActive = true;
                    }
                }

                store.totalPublicBalance = Number(pubTotal).toFixed(2);
                store.totalShieldedBalance = Number(privTotal).toFixed(2);

                if (!foundActive && res.accounts.length > 0) {
                    store.activeAccount = res.accounts[0];
                }

                store.accountsUpdated();
            }
        });
    }

    function selectAccount(account) {
        store.activeAccount = account;
        store.accountSelected(account);
    }

    function createAccount(label, isPrivate, callback) {
        var method = isPrivate ? "createPrivateAccount" : "createPublicAccount";
        bridge.invoke(method, [label || (isPrivate ? "Shielded Account" : "Public Account")], function(res) {
            store.refreshAccounts();
            if (callback) callback(res);
        });
    }

    function setAccountLabel(accountId, label, isPrivate, callback) {
        bridge.invoke("setAccountLabel", [accountId, label, isPrivate], function(res) {
            store.refreshAccounts();
            if (callback) callback(res);
        });
    }

    function refreshTokens() {
        bridge.invoke("listTokenHoldings", [], function(res) {
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
