import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Rectangle {
    id: lockScreen

    required property var bridge
    required property var accountStore

    signal openRestoreModal

    color: theme.bgCanvas

    property string errorMessage: ""
    property bool isUnlocking: false

    Theme {
        id: theme
    }

    Item {
        anchors.fill: parent

        Card {
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 380)
            title: "Keystore Locked"
            subtitle: "Argon2id + AES-256-GCM Memory Protection"

            ColumnLayout {
                width: parent.width
                spacing: 16

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: theme.borderSubtle
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "Master Vault Password"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: Font.DemiBold
                    }

                    TextField {
                        id: passInput
                        Layout.fillWidth: true
                        placeholder: "Enter master passphrase to decrypt..."
                        echoMode: TextInput.Password
                        onAccepted: lockScreen.unlock()
                    }
                }

                Text {
                    visible: lockScreen.errorMessage.length > 0
                    Layout.fillWidth: true
                    text: lockScreen.errorMessage
                    color: theme.statusDanger
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 12
                    spacing: 12

                    Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        text: "Restore from Seed"
                        isPrimary: false
                        isFlat: true
                        onClicked: {
                            lockScreen.openRestoreModal();
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        text: lockScreen.isUnlocking ? "Decrypting Vault..." : "Unlock Keystore"
                        isPrimary: true
                        isFlat: true
                        enabled: !lockScreen.isUnlocking && passInput.text.length > 0
                        onClicked: lockScreen.unlock()
                    }
                }
            }
        }
    }

    function unlock() {
        if (passInput.text.length === 0)
            return;
        lockScreen.errorMessage = "";
        lockScreen.isUnlocking = true;

        bridge.invoke("unlockWallet", [passInput.text], function (res) {
            if (res && res.ok) {
                passInput.text = "";
                accountStore.refreshAccounts(function () {
                    lockScreen.isUnlocking = false;
                });
                accountStore.refreshTokens();
            } else {
                lockScreen.isUnlocking = false;
                lockScreen.errorMessage = res && res.error ? res.error : "Incorrect password or decryption failed";
            }
        });
    }
}
