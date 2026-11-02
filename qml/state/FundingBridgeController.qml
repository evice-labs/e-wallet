import QtQuick

Item {
    id: ctrl

    required property var bridge
    required property var accountStore

    property string nodeUrl: "http://127.0.0.1:8080"
    property bool isMining: false
    property int hashrate: 0
    property string unbridgedL1Tokens: "0.00 LOGOS"
    property int blocksMined: 0
    property string statusMessage: ""
    property bool isSuccessStatus: true
    property bool isDepositing: false
    property bool nodeOnline: false

    readonly property bool hasUnbridgedTokens: {
        var num = parseFloat(unbridgedL1Tokens);
        return !isNaN(num) && num > 0;
    }

    signal depositSuccess(string amount, string txHash)
    signal depositFailed(string reason)

    Timer {
        id: telemetryTimer
        interval: 2000
        repeat: true
        running: ctrl.isMining
        onTriggered: {
            ctrl.checkPowStatus();
        }
    }

    function checkPowStatus() {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", ctrl.nodeUrl + "/pow/status", true);
        xhr.timeout = 2500;
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    ctrl.nodeOnline = true;
                    try {
                        var res = JSON.parse(xhr.responseText);
                        if (res.hashrate !== undefined)
                            ctrl.hashrate = res.hashrate;
                        if (res.unbridged_balance !== undefined)
                            ctrl.unbridgedL1Tokens = res.unbridged_balance + " LOGOS";
                        if (res.is_mining !== undefined)
                            ctrl.isMining = res.is_mining;
                        if (res.blocks_mined !== undefined)
                            ctrl.blocksMined = res.blocks_mined;
                    } catch (e) {}
                } else {
                    ctrl.nodeOnline = false;
                }
            }
        };
        try {
            xhr.send();
        } catch (e) {
            ctrl.nodeOnline = false;
        }
    }

    function startMining() {
        ctrl.isMining = true;
        ctrl.statusMessage = "EmPoWer mining worker started. Contacting L1 node...";
        ctrl.isSuccessStatus = true;

        var xhr = new XMLHttpRequest();
        xhr.open("POST", ctrl.nodeUrl + "/pow/mining/start", true);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.timeout = 2000;
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                ctrl.checkPowStatus();
            }
        };
        try {
            xhr.send(JSON.stringify({
                threads: 4
            }));
        } catch (e) {}
    }

    function stopMining() {
        ctrl.isMining = false;
        ctrl.hashrate = 0;
        ctrl.statusMessage = "EmPoWer mining worker stopped.";
        ctrl.isSuccessStatus = true;

        var xhr = new XMLHttpRequest();
        xhr.open("POST", ctrl.nodeUrl + "/pow/mining/stop", true);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.timeout = 2000;
        xhr.onreadystatechange = function () {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                ctrl.checkPowStatus();
            }
        };
        try {
            xhr.send(JSON.stringify({}));
        } catch (e) {}
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

        var amountVal = parseFloat(ctrl.unbridgedL1Tokens);
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

        var amountStr = amountVal.toFixed(2);
        ctrl.isDepositing = true;
        ctrl.statusMessage = "Broadcasting on-chain ChannelDeposit transaction...";
        ctrl.isSuccessStatus = true;

        bridge.invoke("channelDeposit", [activeAcc.account_id, amountStr], function (res) {
            ctrl.isDepositing = false;
            if (res && res.ok) {
                var txHash = res.tx_hash || "";
                ctrl.unbridgedL1Tokens = "0.00 LOGOS";
                ctrl.statusMessage = "ChannelDeposit confirmed! +" + amountStr + " LEZ credited to " + (activeAcc.label || activeAcc.account_id) + ".";
                ctrl.isSuccessStatus = true;
                accountStore.refreshAccounts();
                ctrl.depositSuccess(amountStr, txHash);
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
