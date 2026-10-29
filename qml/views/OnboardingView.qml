import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Rectangle {
    id: onboardingView

    required property var bridge
    required property var accountStore

    signal openRestoreModal()

    color: theme.bgCanvas

    property int currentStep: 1 // 1: Mode Select, 2: Set Password, 3: Backup Seed, 4: Complete
    property string masterPassword: ""
    property var mnemonicWords: []
    property string errorMessage: ""
    property bool isCreating: false

    Theme { id: theme }

    Item {
        anchors.fill: parent

        // Centered Neo-Skeuomorphic Onboarding Card
        Card {
            id: mainCard
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 600)
            title: {
                if (currentStep === 1) return "WELCOME TO EVICE WALLET";
                if (currentStep === 2) return "STEP 1: SECURE YOUR KEYSTORE";
                if (currentStep === 3) return "STEP 2: BACKUP RECOVERY PHRASE";
                return "SETUP COMPLETE";
            }
            subtitle: {
                if (currentStep === 1) return "Logos Execution Zone (LEZ) Multi-Account & Shielded Vault";
                if (currentStep === 2) return "Set Master Passphrase for Argon2id AES-256-GCM Vault";
                if (currentStep === 3) return "12-Word BIP-39 Master Recovery Phrase";
                return "Your Keystore is Ready for LEZ Testnet 0.4";
            }

            ColumnLayout {
                width: parent.width
                spacing: 16

                // INITIAL CHOICE
                ColumnLayout {
                    visible: onboardingView.currentStep === 1
                    Layout.fillWidth: true
                    spacing: 14

                    Text {
                        Layout.fillWidth: true
                        text: "Evice Wallet is a native Logos Basecamp module providing multi-account key management, zero-knowledge shielded transactions, and LNS domain resolution on the Logos Execution Zone."
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeBody
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: "LEZ TESTNET 0.4"
                            color: theme.statusSuccess
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeTiny
                            font.weight: Font.Bold
                        }

                        Text {
                            text: "ZK-SNARK SHIELDED CIRCUIT"
                            color: theme.statusShielded
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeTiny
                            font.weight: Font.Bold
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: 1
                        color: theme.borderSubtle
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Button {
                            Layout.fillWidth: true
                            text: "Restore Existing Vault"
                            isPrimary: false
                            onClicked: {
                                onboardingView.openRestoreModal();
                            }
                        }

                        Button {
                            Layout.fillWidth: true
                            text: "Create New Vault"
                            isPrimary: true
                            onClicked: {
                                onboardingView.currentStep = 2;
                            }
                        }
                    }
                }

                // MASTER PASSWORD
                ColumnLayout {
                    visible: onboardingView.currentStep === 2
                    Layout.fillWidth: true
                    spacing: 14

                    Text {
                        Layout.fillWidth: true
                        text: "Create a strong master passphrase to encrypt your root BIP-39 keystore on disk. Decryption keys are cleared from volatile memory automatically after 15 minutes of inactivity."
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeBody
                        wrapMode: Text.WordWrap
                    }

                    TextField {
                        id: pass1
                        Layout.fillWidth: true
                        label: "Master Password"
                        placeholder: "Enter at least 8 characters..."
                        echoMode: TextInput.Password
                    }

                    TextField {
                        id: pass2
                        Layout.fillWidth: true
                        label: "Confirm Master Password"
                        placeholder: "Re-enter master password..."
                        echoMode: TextInput.Password
                    }

                    Text {
                        visible: onboardingView.errorMessage.length > 0
                        Layout.fillWidth: true
                        text: onboardingView.errorMessage
                        color: theme.statusDanger
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Button {
                            text: "Back"
                            isPrimary: false
                            onClicked: {
                                onboardingView.errorMessage = "";
                                onboardingView.currentStep = 1;
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: onboardingView.isCreating ? "Generating Seed..." : "Generate Recovery Phrase"
                            isPrimary: true
                            enabled: !onboardingView.isCreating
                            onClicked: {
                                onboardingView.errorMessage = "";
                                var p1 = pass1.text;
                                var p2 = pass2.text;
                                if (p1.length < 8) {
                                    onboardingView.errorMessage = "Password must be at least 8 characters long";
                                    return;
                                }
                                if (p1 !== p2) {
                                    onboardingView.errorMessage = "Passwords do not match";
                                    return;
                                }

                                onboardingView.masterPassword = p1;
                                onboardingView.isCreating = true;

                                bridge.invoke("createWallet", [p1], function(res) {
                                    onboardingView.isCreating = false;
                                    if (res && res.ok && res.mnemonic) {
                                        onboardingView.mnemonicWords = res.mnemonic.trim().split(/\s+/);
                                        onboardingView.currentStep = 3;
                                    } else {
                                        onboardingView.errorMessage = res && res.error ? res.error : "Failed to generate wallet";
                                    }
                                });
                            }
                        }
                    }
                }

                // 12-WORD MNEMONIC DISPLAY
                ColumnLayout {
                    visible: onboardingView.currentStep === 3
                    Layout.fillWidth: true
                    spacing: 14

                    Text {
                        Layout.fillWidth: true
                        text: "Write down these 12 secret words in numerical order and keep them in a safe offline location. Do not share or store them in plain text."
                        color: theme.accentOrange
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeBody
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                    }

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
                                model: onboardingView.mnemonicWords
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

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "BIP-39 STANDARD ROOT SEED"
                            color: theme.statusSuccess
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeTiny
                            font.weight: Font.Bold
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: "I Have Saved My Seed Phrase"
                            isPrimary: true
                            onClicked: {
                                // Create default initial accounts
                                accountStore.createAccount("Primary Vault (Public)", false, function() {
                                    accountStore.createAccount("Stealth Stash (Shielded)", true, function() {
                                        accountStore.refreshAccounts();
                                        accountStore.refreshTokens();
                                        bridge.isInitialized = true;
                                        bridge.isLocked = false;
                                        bridge.walletStateChanged();
                                    });
                                });
                            }
                        }
                    }
                }
            }
        }
    }
}
