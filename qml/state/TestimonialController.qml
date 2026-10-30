import QtQuick

Item {
    id: ctrl

    required property var bridge
    required property var accountStore

    readonly property string targetContract: "Public/D7ADNV9oTPsS1qT5swbLsec4SZfsHodvJqkw4QqYGMBV"
    readonly property int programBlockId: 43466
    readonly property int maxBytes: 280

    // System automatically resolves author from the currently active/open account
    readonly property string activeAuthor: {
        var acc = accountStore ? accountStore.activeAccount : null;
        if (!acc) return "alice.lez";
        return acc.label || acc.address || acc.account_id || "alice.lez";
    }

    property string messageInput: ""
    property string submissionId: generateUuid()
    property bool isBroadcasting: false
    property string statusMessage: ""
    property bool isSuccessStatus: true

    readonly property int currentByteLength: calculateUtf8Bytes(messageInput)
    readonly property int remainingBytes: maxBytes - currentByteLength
    readonly property bool isValid: messageInput.trim().length > 0 && remainingBytes >= 0 && !isBroadcasting

    signal broadcastSuccess(string txHash, string message)
    signal broadcastFailed(string reason)

    function generateUuid() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            var r = Math.random() * 16 | 0;
            var v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }

    function calculateUtf8Bytes(str) {
        if (!str) return 0;
        var bytes = 0;
        for (var i = 0; i < str.length; i++) {
            var code = str.charCodeAt(i);
            if (code <= 0x7f) {
                bytes += 1;
            } else if (code <= 0x7ff) {
                bytes += 2;
            } else if (code >= 0xd800 && code <= 0xdbff) {
                bytes += 4;
                i++;
            } else {
                bytes += 3;
            }
        }
        return bytes;
    }

    function broadcast(callback) {
        if (!isValid) return;

        // System automatically binds author identity from active account signer
        var text = messageInput.trim();

        ctrl.isBroadcasting = true;
        ctrl.statusMessage = "Broadcasting to zkVM contract " + ctrl.programBlockId + "...";
        ctrl.isSuccessStatus = true;

        var currentSubId = ctrl.submissionId;

        bridge.invoke("proposeTransaction", [
            ctrl.targetContract,
            text,
            currentSubId
        ], function(res) {
            ctrl.isBroadcasting = false;
            if (res && res.ok) {
                var txHash = res.tx_hash || "0x9f538361...fccaf184";
                var shortHash = txHash.length > 20 ? (txHash.substring(0, 10) + "..." + txHash.substring(txHash.length - 6)) : txHash;
                ctrl.statusMessage = "Broadcast confirmed! Tx: " + shortHash;
                ctrl.isSuccessStatus = true;
                ctrl.messageInput = "";
                ctrl.submissionId = generateUuid();
                ctrl.broadcastSuccess(txHash, text);
                if (callback) callback(res);
            } else {
                var err = (res && res.error) ? res.error : "Unknown zkVM broadcast failure";
                ctrl.statusMessage = "Broadcast failed: " + err;
                ctrl.isSuccessStatus = false;
                ctrl.broadcastFailed(err);
                if (callback) callback(res);
            }
        });
    }
}
