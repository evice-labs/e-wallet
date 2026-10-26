import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "Unlock Keystore Vault"
    subtitle: "Argon2id + AES-256-GCM Decryption"
    dialogWidth: 440
    dialogHeight: 310

    required property var bridge

    property string errorMessage: ""

    Theme { id: theme }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        Text {
            Layout.fillWidth: true
            text: "Enter your master password to decrypt cryptographic credentials and authorize transactions."
            color: theme.textSecondary
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeBody
            wrapMode: Text.WordWrap
        }

        TextField {
            id: passwordField
            Layout.fillWidth: true
            placeholder: "Master vault password"
            echoMode: TextInput.Password
            onAccepted: submitUnlock()
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
            spacing: 12

            Button {
                text: "Cancel"
                isPrimary: false
                onClicked: modal.close()
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Unlock Vault"
                isPrimary: true
                enabled: passwordField.text.length > 0
                onClicked: submitUnlock()
            }
        }
    }

    function submitUnlock() {
        if (passwordField.text.length === 0) return;
        modal.errorMessage = "";

        bridge.invoke("unlockWallet", [passwordField.text], function(res) {
            if (res && res.ok) {
                passwordField.text = "";
                modal.close();
            } else {
                modal.errorMessage = res && res.error ? res.error : "Incorrect password or decryption failed";
            }
        });
    }
}
