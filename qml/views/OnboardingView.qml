import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Rectangle {
    id: onboardingView

    required property var bridge
    required property var accountStore

    signal openRestoreModal

    color: theme.bgCanvas

    property int currentStep: 1 // 1: Mode Select, 2: Set Password, 3: Backup Seed, 4: Complete
    property string masterPassword: ""
    property var mnemonicWords: []
    property string errorMessage: ""
    property bool isCreating: false

    Theme {
        id: theme
    }

    Item {
        anchors.fill: parent

        // Step 1: Two-column split card
        Rectangle {
            id: welcomeCard
            visible: onboardingView.currentStep === 1
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 760)
            height: Math.max(welcomeLeftCol.implicitHeight + theme.spacingXlarge * 2, 360)
            radius: theme.radiusCard
            color: theme.bgSurface
            clip: true

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true

                    ColumnLayout {
                        id: welcomeLeftCol
                        anchors.fill: parent
                        anchors.margins: theme.spacingXlarge
                        spacing: 14

                        // Header
                        Text {
                            Layout.fillWidth: true
                            text: "Welcome to Wallez"
                            color: theme.textPrimary
                            font.family: theme.fontFamily
                            font.pixelSize: 34
                            font.weight: Font.Bold
                            wrapMode: Text.WordWrap
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        // Body
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 14

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: theme.borderSubtle
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "Wallez is a native Logos Basecamp app providing multi-account key management, seamless on-chain transfers, testnet token mining, zero-knowledge shielded transactions, and LNS domain resolution on the Logos Execution Zone."
                                color: theme.textSecondary
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSizeBody
                                wrapMode: Text.WordWrap
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Text {
                                    text: "LOGOS LEZ TESTNET 0.4"
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

                                Item {
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        // Footer
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            Button {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                text: "Restore Existing Vault"
                                isPrimary: false
                                isFlat: true
                                onClicked: {
                                    onboardingView.openRestoreModal();
                                }
                            }

                            Button {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 1
                                text: "Create New Vault"
                                isPrimary: true
                                isFlat: true
                                onClicked: {
                                    onboardingView.currentStep = 2;
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: Qt.resolvedUrl("../assets/sailBroad.jpg")
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
            }
        }

        // Steps 2-4: Standard Onboarding Card
        Card {
            id: mainCard
            visible: onboardingView.currentStep !== 1
            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 600)
            title: {
                if (currentStep === 2)
                    return "Step 1: Secure Your Keystore";
                if (currentStep === 3)
                    return "Step 2: Backup Recovery Phrase";
                return "Setup Complete";
            }

            ColumnLayout {
                width: parent.width
                spacing: 16

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

                        Item {
                            Layout.fillWidth: true
                        }

                        Button {
                            text: onboardingView.isCreating ? "Generating Seed..." : "Generate Recovery Phrase"
                            isPrimary: true
                            isFlat: true
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

                                bridge.invoke("createWallet", [p1], function (res) {
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

                // MNEMONIC DISPLAY
                ColumnLayout {
                    visible: onboardingView.currentStep === 3
                    Layout.fillWidth: true
                    spacing: 14

                    Text {
                        Layout.fillWidth: true
                        text: "Write down these " + onboardingView.mnemonicWords.length + " secret words in numerical order and keep them in a safe offline location. Do not share or store them in plain text."
                        color: theme.accentOrange
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeBody
                        font.weight: Font.Medium
                        wrapMode: Text.WordWrap
                    }

                    InsetPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.max(180, seedGrid.implicitHeight + 32)

                        GridLayout {
                            id: seedGrid
                            anchors.centerIn: parent
                            columns: 3
                            rowSpacing: 12
                            columnSpacing: 24

                            Repeater {
                                model: onboardingView.mnemonicWords
                                delegate: Row {
                                    Layout.preferredWidth: 120
                                    Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                                    spacing: 6
                                    Text {
                                        text: (index + 1) + "."
                                        color: theme.textMuted
                                        font.family: theme.fontMono
                                        font.pixelSize: theme.fontSizeSmall
                                        width: 24
                                        horizontalAlignment: Text.AlignRight
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

                        Item {
                            Layout.fillWidth: true
                        }

                        Button {
                            text: "I Have Saved My Seed Phrase"
                            isPrimary: true
                            isFlat: true
                            onClicked: {
                                bridge.isInitialized = true;
                                bridge.isLocked = false;
                                bridge.ensureActiveSession(function () {
                                    accountStore.refreshAccounts();
                                    accountStore.refreshTokens();
                                    bridge.walletStateChanged();
                                });
                            }
                        }
                    }
                }
            }
        }
    }
}
