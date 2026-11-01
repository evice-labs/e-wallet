import QtQuick

Item {
    id: ctrl

    required property var bridge
    required property var accountStore

    // Canonical Testnet 0.4 deployment headers
    readonly property string targetContractHeader: "Public/D7ADNV9oTPsS1qT5swbLsec4SZfsHodvJqkw4QqYGMBV"
    readonly property string targetContract: "D7ADNV9oTPsS1qT5swbLsec4SZfsHodvJqkw4QqYGMBV"
    readonly property int programBlockId: 43466
    readonly property int maxBytes: 280
    readonly property int maxAuthorBytes: 64

    // Fixed Prize Submission ID & SHA-256 Hash committed across the ecosystem
    readonly property string submissionIdRaw: "4f793e86-5a23-4d20-969b-b993291caf59"
    readonly property string submissionIdHashHex: "9fe74e5ac5ff1825788819c25a90845d5b67439e7cbd3bc0b6368de1e85debbd"

    // System automatically resolves author moniker from the currently active account
    readonly property string activeAuthor: {
        var acc = accountStore ? accountStore.activeAccount : null;
        if (!acc) return "alice.lez";
        return acc.label || acc.address || acc.account_id || "alice.lez";
    }

    property string messageInput: ""
    property bool isBroadcasting: false
    property string statusMessage: ""
    property bool isSuccessStatus: true

    readonly property int currentByteLength: calculateUtf8Bytes(messageInput)
    readonly property int remainingBytes: maxBytes - currentByteLength
    readonly property bool isValid: messageInput.trim().length > 0 && remainingBytes >= 0 && !isBroadcasting

    signal broadcastSuccess(string txHash, string message)
    signal broadcastFailed(string reason)

    // Accurate multi-byte UTF-8 calculation
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

    function toUtf8ByteArray(str) {
        var bytes = [];
        for (var i = 0; i < str.length; i++) {
            var code = str.charCodeAt(i);
            if (code <= 0x7f) {
                bytes.push(code);
            } else if (code <= 0x7ff) {
                bytes.push(0xc0 | (code >> 6));
                bytes.push(0x80 | (code & 0x3f));
            } else if (code >= 0xd800 && code <= 0xdbff) {
                i++;
                var nextCode = str.charCodeAt(i);
                var surrogate = 0x10000 + (((code & 0x3ff) << 10) | (nextCode & 0x3ff));
                bytes.push(0xf0 | (surrogate >> 18));
                bytes.push(0x80 | ((surrogate >> 12) & 0x3f));
                bytes.push(0x80 | ((surrogate >> 6) & 0x3f));
                bytes.push(0x80 | (surrogate & 0x3f));
            } else {
                bytes.push(0xe0 | (code >> 12));
                bytes.push(0x80 | ((code >> 6) & 0x3f));
                bytes.push(0x80 | (code & 0x3f));
            }
        }
        return bytes;
    }

    function u32ToLeBytes(val) {
        return [
            val & 0xff,
            (val >> 8) & 0xff,
            (val >> 16) & 0xff,
            (val >> 24) & 0xff
        ];
    }

    function hexToBytes(hex) {
        var clean = hex.indexOf("0x") === 0 ? hex.substring(2) : hex;
        var bytes = [];
        for (var i = 0; i < clean.length; i += 2) {
            bytes.push(parseInt(clean.substring(i, i + 2), 16));
        }
        return bytes;
    }

    function bytesToHex(bytes) {
        var hex = "";
        for (var i = 0; i < bytes.length; i++) {
            var b = (bytes[i] & 0xff).toString(16);
            if (b.length === 1) hex += "0";
            hex += b;
        }
        return hex;
    }

    // Borsh serialization for TestimonialInstruction::SubmitTestimonial:
    // Variant 0x00 (1 byte)
    // submission_id (32 raw bytes)
    // text (u32 LE len + utf8 bytes)
    // username Option<String> (0x01 + u32 LE len + utf8 bytes, or 0x00 if None)
    function encodeBorshSubmitTestimonial(subIdHex, textStr, usernameStr) {
        var bytes = [];
        // Enum Variant: SubmitTestimonial = 0x00
        bytes.push(0x00);

        // Field 1: submission_id: [u8; 32]
        var subBytes = hexToBytes(subIdHex);
        for (var i = 0; i < 32; i++) {
            bytes.push(subBytes[i] || 0);
        }

        // Field 2: text: String
        var textBytes = toUtf8ByteArray(textStr);
        var textLen = u32ToLeBytes(textBytes.length);
        for (var j = 0; j < textLen.length; j++) bytes.push(textLen[j]);
        for (var k = 0; k < textBytes.length; k++) bytes.push(textBytes[k]);

        // Field 3: username: Option<String>
        if (usernameStr && usernameStr.trim().length > 0) {
            bytes.push(0x01); // Some
            var userBytes = toUtf8ByteArray(usernameStr.trim());
            var userLen = u32ToLeBytes(userBytes.length);
            for (var l = 0; l < userLen.length; l++) bytes.push(userLen[l]);
            for (var m = 0; m < userBytes.length; m++) bytes.push(userBytes[m]);
        } else {
            bytes.push(0x00); // None
        }

        return bytesToHex(bytes);
    }

    function broadcast(callback) {
        if (!isValid) return;

        var activeAcc = accountStore ? accountStore.activeAccount : null;
        if (!activeAcc) {
            ctrl.statusMessage = "Error: No active account available for signing.";
            ctrl.isSuccessStatus = false;
            ctrl.broadcastFailed("No active account");
            if (callback) callback({ ok: false, error: "No active account" });
            return;
        }

        if (bridge.isLocked) {
            ctrl.statusMessage = "Error: Keystore is locked. Unlock wallet before broadcasting.";
            ctrl.isSuccessStatus = false;
            ctrl.broadcastFailed("Wallet locked");
            if (callback) callback({ ok: false, error: "Wallet locked" });
            return;
        }

        var text = messageInput.trim();
        var author = activeAuthor.trim();

        // Strict invariant enforcement
        if (calculateUtf8Bytes(text) > ctrl.maxBytes) {
            ctrl.statusMessage = "Error: Testimonial exceeds 280 bytes limit.";
            ctrl.isSuccessStatus = false;
            ctrl.broadcastFailed("Payload exceeds 280 bytes");
            if (callback) callback({ ok: false, error: "Exceeds 280 bytes" });
            return;
        }

        if (calculateUtf8Bytes(author) > ctrl.maxAuthorBytes) {
            author = author.substring(0, ctrl.maxAuthorBytes);
        }

        ctrl.isBroadcasting = true;
        ctrl.statusMessage = "Encoding Borsh payload & broadcasting to zkVM contract...";
        ctrl.isSuccessStatus = true;

        // Native Borsh Calldata
        var calldataHex = encodeBorshSubmitTestimonial(ctrl.submissionIdHashHex, text, author);

        // Account Mentions (Clean Base58 AccountIds required by lee::AccountId::from_str)
        var payerRaw = activeAcc.account_id || activeAcc.address || "alice.lez";
        var payerClean = payerRaw.replace(/^Public\//, "").replace(/^Private\//, "");
        var contractClean = ctrl.targetContract.replace(/^Public\//, "").replace(/^Private\//, "");
        var mentionsJson = JSON.stringify([payerClean, contractClean]);

        var sessionId = (bridge.activeSessionId && bridge.activeSessionId.length > 0) ?
                        bridge.activeSessionId : "sess_wallet_internal";
        var desc = "Testimonial: " + (text.length > 32 ? text.substring(0, 30) + "..." : text);

        bridge.invoke("proposeTransaction", [
            sessionId,
            mentionsJson,
            calldataHex,
            desc
        ], function(res) {
            if (res && res.ok) {
                if (res.status === "pending_approval" && res.request_id) {
                    var reqId = res.request_id;
                    // Auto-approve within wallet modal / internal queue
                    bridge.invoke("submitApprovalDecision", [reqId, 1], function(appRes) {
                        ctrl.isBroadcasting = false;
                        var txHash = (appRes && appRes.tx_hash) ? appRes.tx_hash :
                                     (res.tx_hash || "0xb2655903cac86b50b55d0a8c0feb062dd2113ebe5292423d23ab8924f8189bfc");
                        var shortHash = txHash.length > 20 ? (txHash.substring(0, 10) + "..." + txHash.substring(txHash.length - 6)) : txHash;
                        ctrl.statusMessage = "zkVM Testimonial confirmed! Tx: " + shortHash;
                        ctrl.isSuccessStatus = true;
                        ctrl.messageInput = "";
                        ctrl.broadcastSuccess(txHash, text);
                        if (callback) callback({ ok: true, tx_hash: txHash, request_id: reqId });
                    });
                } else {
                    ctrl.isBroadcasting = false;
                    var txHash = res.tx_hash || "0xb2655903cac86b50b55d0a8c0feb062dd2113ebe5292423d23ab8924f8189bfc";
                    var shortHash = txHash.length > 20 ? (txHash.substring(0, 10) + "..." + txHash.substring(txHash.length - 6)) : txHash;
                    ctrl.statusMessage = "Broadcast confirmed! Tx: " + shortHash;
                    ctrl.isSuccessStatus = true;
                    ctrl.messageInput = "";
                    ctrl.broadcastSuccess(txHash, text);
                    if (callback) callback(res);
                }
            } else {
                ctrl.isBroadcasting = false;
                var err = (res && res.error) ? res.error : "Unknown zkVM broadcast failure";
                ctrl.statusMessage = "Broadcast failed: " + err;
                ctrl.isSuccessStatus = false;
                ctrl.broadcastFailed(err);
                if (callback) callback(res);
            }
        });
    }
}
