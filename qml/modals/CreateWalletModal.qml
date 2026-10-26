import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: step === 1 ? "Initialize New Hardware Keystore" : "Backup Secret Recovery Phrase"
    subtitle: step === 1 ? "Step 1: Set Master Vault Password" : "Step 2: 12-Word BIP-39 Mnemonic"
    dialogWidth: 540
    dialogHeight: step === 1 ? 380 : 490
    dismissible: step === 1

    required property var bridge
    required property var accountStore

    property int step: 1
    property var mnemonicWords: []
    property string errorMessage: ""

    Theme { id: theme }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        // STEP 1: PASSWORD CREATION
        ColumnLayout {
            visible: modal.step === 1
            Layout.fillWidth: true
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Your password encrypts the wallet vault on disk using Argon2id with AES-256-GCM. Choose a strong, memorable passphrase."
                color: theme.textSecondary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeBody
                wrapMode: Text.WordWrap
            }

            TextField {
                id: passInput
                Layout.fillWidth: true
                placeholder: "Master password (min 8 chars)"
                echoMode: TextInput.Password
            }

            TextField {
                id: confirmPassInput
                Layout.fillWidth: true
                placeholder: "Confirm master password"
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
                    text: "Generate Vault"
                    isPrimary: true
                    onClicked: generateWallet()
                }
            }
        }

        // STEP 2: MNEMONIC BACKUP DISPLAY
        ColumnLayout {
            visible: modal.step === 2
            Layout.fillWidth: true
            spacing: 14

            Text {
                Layout.fillWidth: true
                text: "Write down these 12 words in exact order and store them in a secure offline location. Anyone with access to these words can access your funds."
                color: theme.accentOrange
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeBody
                font.weight: Font.Medium
                wrapMode: Text.WordWrap
            }

            // Monospace Inset Grid for Mnemonic Words
            InsetPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 180

                GridLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    columns: 3
                    rowSpacing: 10
                    columnSpacing: 12

                    Repeater {
                        model: modal.mnemonicWords
                        delegate: Row {
                            spacing: 6
                            Text {
                                text: (index + 1) + "."
                                color: theme.textMuted
                                font.family: theme.fontMono
                                font.pixelSize: theme.fontSizeSmall
                                width: 22
                            }
                            Text {
                                text: modelData
                                color: theme.textPrimary
                                font.family: theme.fontMono
                                font.pixelSize: theme.fontSizeBody
                                font.weight: Font.Bold
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true

                PillBadge {
                    text: "BIP-39 Standalone Seed"
                    badgeColor: theme.statusSuccess
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "I Have Saved My Seed Phrase"
                    isPrimary: true
                    onClicked: finishSetup()
                }
            }
        }
    }

    function generateWallet() {
        modal.errorMessage = "";
        var p1 = passInput.text;
        var p2 = confirmPassInput.text;

        if (p1.length < 8) {
            modal.errorMessage = "Password must be at least 8 characters long";
            return;
        }
        if (p1 !== p2) {
            modal.errorMessage = "Passwords do not match";
            return;
        }

        bridge.invoke("createWallet", [p1], function(res) {
            if (res && res.ok && res.mnemonic) {
                modal.mnemonicWords = res.mnemonic.trim().split(/\s+/);
                modal.step = 2;
            } else {
                modal.errorMessage = res && res.error ? res.error : "Failed to initialize wallet";
            }
        });
    }

    function finishSetup() {
        passInput.text = "";
        confirmPassInput.text = "";
        modal.step = 1;
        modal.mnemonicWords = [];
        accountStore.refreshAccounts();
        modal.close();
    }
}
