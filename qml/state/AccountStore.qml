import QtQuick

Item {
    id: store

    required property var bridge

    property var accounts: []
    property var activeAccount: null
    property string totalPublicBalance: "0.00"
    property string totalShieldedBalance: "0.00"
    property bool isLoading: false

    signal accountSelected(var account)
    signal accountsUpdated()

    Connections {
        target: bridge
        function onWalletStateChanged() {
            if (!bridge.isLocked) {
                store.refreshAccounts();
            } else {
                store.accounts = [];
                store.activeAccount = null;
                store.totalPublicBalance = "0.00";
                store.totalShieldedBalance = "0.00";
                store.accountsUpdated();
            }
        }
    }

    Component.onCompleted: {
        if (!bridge.isLocked) {
            refreshAccounts();
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

                store.totalPublicBalance = pubTotal.toLocaleString(Qt.locale(), "f", 2);
                store.totalShieldedBalance = privTotal.toLocaleString(Qt.locale(), "f", 2);

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
}
