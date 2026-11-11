import QtQuick

Item {
    id: ctrl

    required property var bridge
    required property var accountStore

    property string nodeUrl: "http://127.0.0.1:8080"
    property bool isMining: false
    property int hashrate: 0
    property string unbridgedRawBalance: "0"
    property string unbridgedL1Tokens: "0 LOGOS"
    property int blocksMined: 0
    property string statusMessage: ""
    property bool isSuccessStatus: true
    property bool isDepositing: false
    property bool nodeOnline: false

    readonly property bool hasUnbridgedTokens: {
        var cleaned = String(unbridgedRawBalance).replace(/,/g, "");
        var num = parseFloat(cleaned);
        return !isNaN(num) && num > 0;
    }

    signal depositInitiated(string amount, string targetAccountId)
    signal depositSuccess(string amount, string txHash)
    signal depositFailed(string reason)

    Component.onCompleted: {
        if (bridge.isInitialized && !bridge.isLocked) {
            ctrl.checkPowStatus();
        }
    }

    Connections {
        target: bridge
        function onWalletStateChanged() {
            if (bridge.isInitialized && !bridge.isLocked) {
                ctrl.checkPowStatus();
            } else {
                ctrl.isMining = false;
                ctrl.hashrate = 0;
            }
        }
    }

    Connections {
        target: accountStore
        function onActiveAccountChanged() {
            var activeAcc = accountStore.activeAccount;
            if (activeAcc && (activeAcc.is_private === true || activeAcc.privacy === "private") && ctrl.isMining) {
                ctrl.stopMining();
                ctrl.statusMessage = "Notice: Switched to Shielded account. EmPoWer mining paused.";
                ctrl.isSuccessStatus = false;
            }
        }
    }

    Timer {
        id: telemetryTimer
        interval: 1500
        repeat: true
        running: ctrl.isMining
        onTriggered: {
            ctrl.checkPowStatus();
        }
    }

    Timer {
        id: postDepositRefreshTimer
        interval: 2000
        repeat: false
        running: false
        onTriggered: {
            if (accountStore)
                accountStore.refreshAccounts();
        }
    }

    function applyPowStatus(res) {
        if (!res || !res.ok)
            return;
        if (res.node_online !== undefined)
            ctrl.nodeOnline = !!res.node_online;
        if (res.hashrate !== undefined)
            ctrl.hashrate = Number(res.hashrate) || 0;
        if (res.is_mining !== undefined)
            ctrl.isMining = !!res.is_mining;
        if (res.blocks_mined !== undefined)
            ctrl.blocksMined = Number(res.blocks_mined) || 0;
        if (res.unbridged_balance !== undefined) {
            ctrl.unbridgedRawBalance = String(res.unbridged_balance);
            var formatted = res.formatted_unbridged_balance ? String(res.formatted_unbridged_balance) : String(res.unbridged_balance);
            var cleanFormatted = formatted.split(".")[0];
            if (accountStore && cleanFormatted.indexOf(",") === -1) {
                cleanFormatted = accountStore.formatThousands(cleanFormatted);
            }
            ctrl.unbridgedL1Tokens = (cleanFormatted || "0") + " LOGOS";
        }
    }

    function checkPowStatus() {
        if (!bridge.isHostAvailable || bridge.isLocked)
            return;

        bridge.invoke("getPowStatus", [], function (res) {
            ctrl.applyPowStatus(res);
        });
    }

    function startMining() {
        var activeAcc = accountStore.activeAccount;
        if (activeAcc && (activeAcc.is_private === true || activeAcc.privacy === "private")) {
            ctrl.statusMessage = "Notice: EmPoWer Mining is only available for Public accounts. Please select a Public account.";
            ctrl.isSuccessStatus = false;
            return;
        }

        if (bridge.isLocked) {
            ctrl.statusMessage = "Error: Unlock wallet keystore before starting EmPoWer mining.";
            ctrl.isSuccessStatus = false;
            return;
        }

        ctrl.isMining = true;
        ctrl.statusMessage = "EmPoWer mining worker active via native SDK engine.";
        ctrl.isSuccessStatus = true;

        bridge.invoke("startPowMining", [4], function (res) {
            if (res && res.ok) {
                ctrl.applyPowStatus(res);
            } else {
                ctrl.isMining = false;
                ctrl.hashrate = 0;
                ctrl.statusMessage = (res && res.error) ? ("Mining error: " + res.error) : "Failed to start EmPoWer miner.";
                ctrl.isSuccessStatus = false;
            }
        });
    }

    function stopMining() {
        ctrl.isMining = false;
        ctrl.hashrate = 0;
        ctrl.statusMessage = "EmPoWer mining worker stopped.";
        ctrl.isSuccessStatus = true;

        bridge.invoke("stopPowMining", [], function (res) {
            ctrl.applyPowStatus(res);
        });
    }

    function depositToLez(callback) {
        if (ctrl.isDepositing)
            return;

        var activeAcc = accountStore.activeAccount;
        if (!activeAcc) {
            ctrl.statusMessage = "Error: No active LEZ account selected for bridging.";
            ctrl.isSuccessStatus = false;
            if (callback)
                callback({
                    ok: false,
                    error: "No active account"
                });
            return;
        }

        if (activeAcc.is_private === true || activeAcc.privacy === "private") {
            ctrl.statusMessage = "Error: Cannot bridge to a Private account (funds will be locked on transparent state). Please select a Public account.";
            ctrl.isSuccessStatus = false;
            if (callback)
                callback({
                    ok: false,
                    error: "Private accounts cannot receive transparent L1 bridge deposits"
                });
            return;
        }

        if (bridge.isLocked) {
            ctrl.statusMessage = "Error: Unlock wallet keystore before initiating bridge deposit.";
            ctrl.isSuccessStatus = false;
            if (callback)
                callback({
                    ok: false,
                    error: "Wallet locked"
                });
            return;
        }

        var rawClean = String(ctrl.unbridgedRawBalance).replace(/,/g, "").trim();
        var amountVal = parseFloat(rawClean);
        if (isNaN(amountVal) || amountVal <= 0) {
            ctrl.statusMessage = "No unbridged L1 tokens available to deposit.";
            ctrl.isSuccessStatus = false;
            if (callback)
                callback({
                    ok: false,
                    error: "Zero balance"
                });
            return;
        }

        var amountStr = String(Math.floor(amountVal));
        ctrl.isDepositing = true;
        ctrl.statusMessage = "Broadcasting on-chain ChannelDeposit transaction...";
        ctrl.isSuccessStatus = true;
        ctrl.depositInitiated(amountStr, activeAcc.account_id);

        bridge.invoke("channelDeposit", [activeAcc.account_id, amountStr], function (res) {
            ctrl.isDepositing = false;
            if (res && res.ok) {
                var txHash = res.tx_hash || "";
                var creditedRaw = res.amount_deposited || amountStr;
                var creditedFormatted = accountStore ? accountStore.formatThousands(creditedRaw) : String(creditedRaw);
                ctrl.unbridgedRawBalance = "0";
                ctrl.unbridgedL1Tokens = "0 LOGOS";
                ctrl.statusMessage = "Deposit broadcasted! +" + creditedFormatted + " LEZ submitted to mempool, awaiting block inclusion...";
                ctrl.isSuccessStatus = true;
                accountStore.refreshAccounts();
                postDepositRefreshTimer.restart();
                ctrl.checkPowStatus();
                ctrl.depositSuccess(creditedFormatted, txHash);
                if (callback)
                    callback(res);
            } else {
                var err = (res && res.error) ? res.error : "ChannelDeposit execution rejected.";
                ctrl.statusMessage = "Bridge error: " + err;
                ctrl.isSuccessStatus = false;
                ctrl.depositFailed(err);
                if (callback)
                    callback(res);
            }
        });
    }
}
