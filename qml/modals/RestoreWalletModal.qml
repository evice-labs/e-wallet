import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "Restore Vault from Secret Phrase"
    subtitle: "Import Existing 12 or 24 Word BIP-39 Mnemonic"
    dialogWidth: 520
    dialogHeight: 460

    required property var bridge
    required property var accountStore

    property string errorMessage: ""

    Theme { id: theme }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        Text {
            Layout.fillWidth: true
            text: "Enter your 12 or 24 word mnemonic phrase separated by spaces, followed by a new master encryption password."
            color: theme.textSecondary
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeBody
            wrapMode: Text.WordWrap
        }

        TextField {
            id: mnemonicInput
            Layout.fillWidth: true
            placeholder: "Enter 12 or 24 words separated by spaces..."
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

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true

            Button {
                text: "Cancel"
                isPrimary: false
                onClicked: modal.close()
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Restore & Unlock"
                isPrimary: true
                onClicked: submitRestore()
            }
        }
    }

    function submitRestore() {
        modal.errorMessage = "";
        var m = mnemonicInput.text.trim();
        var words = m.split(/\s+/);
        if (words.length !== 12 && words.length !== 24) {
            modal.errorMessage = "Mnemonic phrase must be exactly 12 or 24 words (got " + words.length + ")";
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

        bridge.invoke("restoreWallet", [m, p1], function(res) {
            if (res && res.ok) {
                mnemonicInput.text = "";
                newPassInput.text = "";
                confirmPassInput.text = "";
                accountStore.refreshAccounts();
                modal.close();
            } else {
                modal.errorMessage = res && res.error ? res.error : "Failed to restore wallet";
            }
        });
    }
}
