import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Rectangle {
    id: lockScreen

    required property var bridge
    required property var accountStore

    signal openRestoreModal()

    color: theme.bgCanvas

    property string errorMessage: ""
    property bool isUnlocking: false

    Theme { id: theme }

    Item {
        anchors.fill: parent

        Card {
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 480)
            title: "KEYSTORE LOCKED"
            subtitle: "Argon2id + AES-256-GCM Memory Protection"

            ColumnLayout {
                width: parent.width
                spacing: 16

                // Avatar / Active Account greeting
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        implicitWidth: 36
                        implicitHeight: 36
                        radius: 18
                        color: theme.bgSurfaceElevated
                        border.color: theme.borderSubtle
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: {
                                var name = accountStore.activeAccount && accountStore.activeAccount.label ? accountStore.activeAccount.label : "A";
                                return name.substring(0, 1).toUpperCase();
                            }
                            color: theme.textPrimary
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeBody
                            font.weight: Font.Bold
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: {
                                var name = accountStore.activeAccount && accountStore.activeAccount.label ? accountStore.activeAccount.label : "alice.lez";
                                return "Vault: " + name;
                            }
                            color: theme.textPrimary
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeBody
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: "Volatile secrets cleared after inactivity timeout"
                            color: theme.textMuted
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeSmall
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "LOCKED"
                        color: theme.statusDanger
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.Bold
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: theme.borderSubtle
                }

                TextField {
                    id: passInput
                    Layout.fillWidth: true
                    label: "Master Vault Password"
                    placeholder: "Enter master passphrase to decrypt..."
                    echoMode: TextInput.Password
                    onAccepted: unlock()
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
                    spacing: 12

                    Button {
                        text: "Restore from Seed"
                        isPrimary: false
                        isCompact: true
                        onClicked: {
                            lockScreen.openRestoreModal();
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        text: lockScreen.isUnlocking ? "Decrypting Vault..." : "Unlock Keystore"
                        isPrimary: true
                        enabled: !lockScreen.isUnlocking && passInput.text.length > 0
                        onClicked: unlock()
                    }
                }
            }
        }
    }

    function unlock() {
        if (passInput.text.length === 0) return;
        lockScreen.errorMessage = "";
        lockScreen.isUnlocking = true;

        bridge.invoke("unlockWallet", [passInput.text], function(res) {
            lockScreen.isUnlocking = false;
            if (res && res.ok) {
                passInput.text = "";
                accountStore.refreshAccounts();
                accountStore.refreshTokens();
            } else {
                lockScreen.errorMessage = res && res.error ? res.error : "Incorrect password or decryption failed";
            }
        });
    }
}
