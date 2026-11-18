import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "Restore Vault from Secret Phrase"
    dialogWidth: 520
    dialogHeight: Math.max(390, contentCol.implicitHeight + 124)

    required property var bridge
    required property var accountStore

    property string errorMessage: ""

    Theme {
        id: theme
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        spacing: 14

        Text {
            Layout.fillWidth: true
            text: "Enter your 15 word mnemonic phrase separated by spaces, followed by a new master encryption password."
            color: theme.textSecondary
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeBody
            wrapMode: Text.WordWrap
        }

        TextField {
            id: mnemonicInput
            Layout.fillWidth: true
            placeholder: "Enter 15 words separated by spaces..."
        }

        TextField {
            id: newPassInput
            Layout.fillWidth: true
            placeholder: "New master password (min 8 chars)"
            echoMode: TextInput.Password
        }

        TextField {
            id: confirmPassInput
            Layout.fillWidth: true
            placeholder: "Confirm new master password"
            echoMode: TextInput.Password
        }

        Text {
            visible: modal.errorMessage.length > 0
            Layout.fillWidth: true
            text: modal.errorMessage
            color: theme.statusShielded
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
            wrapMode: Text.WordWrap
        }

        Item {
            Layout.fillHeight: true
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "Restore & Unlock"
                isPrimary: true
                isFlat: true
                onClicked: modal.submitRestore()
            }
        }
    }

    function formatRestoreError(rawErr) {
        var msg = String(rawErr || "");
        if (msg.indexOf("InvalidChecksum") !== -1 || msg.indexOf("Invalid mnemonic") !== -1 || msg.indexOf("UnknownWord") !== -1 || msg.indexOf("BadWordCount") !== -1) {
            return "Invalid seed phrase for this keystore: words or word order do not match a valid BIP-39 checksum (" + msg + "). Please verify your seed or create a new wallet.";
        }
        return msg || "Failed to restore wallet";
    }

    function submitRestore() {
        modal.errorMessage = "";
        var m = mnemonicInput.text.trim();
        var words = m.length > 0 ? m.split(/\s+/) : [];
        var validCounts = [12, 15, 18, 21, 24];
        if (validCounts.indexOf(words.length) === -1) {
            modal.errorMessage = "Mnemonic phrase must be 15 words (got " + words.length + ")";
            return;
        }

        var p1 = newPassInput.text;
        var p2 = confirmPassInput.text;
        if (p1.length < 8) {
            modal.errorMessage = "Password must be at least 8 characters long";
            return;
        }
        if (p1 !== p2) {
            modal.errorMessage = "Passwords do not match";
            return;
        }

        bridge.invoke("restoreWallet", [m, p1], function (res) {
            if (res && res.ok) {
                mnemonicInput.text = "";
                newPassInput.text = "";
                confirmPassInput.text = "";
                accountStore.refreshAccounts();
                modal.close();
            } else {
                modal.errorMessage = modal.formatRestoreError(res && res.error ? res.error : "");
            }
        });
    }
}
