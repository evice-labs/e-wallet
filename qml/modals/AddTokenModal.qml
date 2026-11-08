import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "Add Token Holding"
    subtitle: "Track and Manage Fungible Token Program Assets on LEZ"
    dialogWidth: 520
    dialogHeight: 485

    required property var accountStore

    property bool isPrivate: false
    property string errorMessage: ""
    property string selectedPreset: "custom"

    Theme {
        id: theme
    }

    onVisibleChanged: {
        if (visible) {
            resetForm();
        }
    }

    function resetForm() {
        modal.errorMessage = "";
        var act = accountStore && accountStore.activeAccount;
        modal.isPrivate = act ? !!act.is_private : false;
        var actId = act ? act.account_id : "";
        holdingInput.text = actId;
        definitionInput.text = "";
        symbolInput.text = "";
        nameInput.text = "";
        modal.selectedPreset = "custom";
    }

    function selectPrivacyMode(isPriv) {
        modal.isPrivate = isPriv;
        modal.errorMessage = "";
        if (accountStore && accountStore.accounts) {
            for (var i = 0; i < accountStore.accounts.length; i++) {
                var acc = accountStore.accounts[i];
                if (!!acc.is_private === isPriv) {
                    holdingInput.text = acc.account_id;
                    return;
                }
            }
        }
    }

    function applyPreset(preset) {
        modal.errorMessage = "";
        modal.selectedPreset = preset;
        var act = accountStore && accountStore.activeAccount;
        var actId = act ? act.account_id : "";
        if (!holdingInput.text.trim() && actId) {
            holdingInput.text = actId;
        }

        if (preset === "test") {
            // Live on-chain Testnet Token A definition (from lez-programs deployments)
            definitionInput.text = "642odmr8h1SYNkkeFeESuJ3wRWNUmJYY1Yi6KSdFs51s";
            symbolInput.text = "TEST";
            nameInput.text = "Testnet Fungible Token";
        } else if (preset === "lusd") {
            // Live on-chain Testnet Token B definition (from lez-programs deployments)
            definitionInput.text = "5AyxKGHttD31qazmaRDqBM1eF2Yd8NzobZKw3dvdkguj";
            symbolInput.text = "LUSD";
            nameInput.text = "Logos Testnet Stablecoin";
        } else {
            definitionInput.text = "";
            symbolInput.text = "";
            nameInput.text = "";
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // CARD 1: TOKEN SPECIFICATION
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: tokenSpecCol.implicitHeight + 20
            radius: theme.radiusSmall
            color: theme.bgSurface
            border.color: theme.borderSubtle
            border.width: 1

            ColumnLayout {
                id: tokenSpecCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Header inside Card 1: Title and Preset Switcher
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "TOKEN SPECIFICATION"
                        color: theme.textMuted
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.DemiBold
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    SegmentedBar {
                        TabButton {
                            text: "TEST"
                            isActive: modal.selectedPreset === "test"
                            onClicked: applyPreset("test")
                        }

                        TabButton {
                            text: "LUSD"
                            isActive: modal.selectedPreset === "lusd"
                            onClicked: applyPreset("lusd")
                        }

                        TabButton {
                            text: "Custom"
                            isActive: modal.selectedPreset === "custom"
                            onClicked: applyPreset("custom")
                        }
                    }
                }

                // Token Definition ID Field
                TextField {
                    id: definitionInput
                    Layout.fillWidth: true
                    label: "TOKEN DEFINITION / MINT ID"
                    placeholder: "Base58 or 0x-hex Token Definition ID..."
                    onAccepted: submitAddToken()
                }

                // Row: Symbol & Token Name
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    TextField {
                        id: symbolInput
                        Layout.preferredWidth: 130
                        label: "SYMBOL"
                        placeholder: "e.g. TEST"
                        onAccepted: submitAddToken()
                    }

                    TextField {
                        id: nameInput
                        Layout.fillWidth: true
                        label: "TOKEN NAME"
                        placeholder: "e.g. Testnet Fungible Token"
                        onAccepted: submitAddToken()
                    }
                }
            }
        }

        // CARD 2: HOLDING ACCOUNT & PRIVACY CONFIGURATION
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: holdingSpecCol.implicitHeight + 20
            radius: theme.radiusSmall
            color: theme.bgSurface
            border.color: theme.borderSubtle
            border.width: 1

            ColumnLayout {
                id: holdingSpecCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                // Header inside Card 2: Title and Privacy Switcher
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "HOLDING & PRIVACY MODE"
                        color: theme.textMuted
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.DemiBold
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    SegmentedBar {
                        TabButton {
                            text: "Public"
                            isActive: !modal.isPrivate
                            onClicked: selectPrivacyMode(false)
                        }

                        TabButton {
                            text: "Shielded"
                            isActive: modal.isPrivate
                            onClicked: selectPrivacyMode(true)
                        }
                    }
                }

                // Holding Account (ATA / Address) Field
                TextField {
                    id: holdingInput
                    Layout.fillWidth: true
                    label: "HOLDING ACCOUNT (ATA / RECIPIENT)"
                    placeholder: "Holding Account ID (defaults to active account)..."
                    onAccepted: submitAddToken()
                }

                // Informative Context Box
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: modal.isPrivate ? theme.statusShielded : theme.statusPublic
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modal.isPrivate ? "Tokens will be registered under private zero-knowledge shielded state." : "Tokens will be registered under transparent public holding state."
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                        wrapMode: Text.WordWrap
                    }
                }

                // Error message notification
                Text {
                    visible: modal.errorMessage.length > 0
                    Layout.fillWidth: true
                    text: modal.errorMessage
                    color: theme.statusDanger
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }

                // Card Divider before buttons
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: theme.borderSubtle
                }

                // Card Action Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        text: "Cancel"
                        isPrimary: false
                        isCompact: true
                        customHeight: 34
                        onClicked: modal.close()
                    }

                    Button {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        text: "Add Token Holding"
                        isPrimary: true
                        isCompact: true
                        customHeight: 34
                        onClicked: submitAddToken()
                    }
                }
            }
        }
    }

    function submitAddToken() {
        modal.errorMessage = "";
        var hid = holdingInput.text.trim();
        var did = definitionInput.text.trim();
        var sym = symbolInput.text.trim().toUpperCase();
        var nm = nameInput.text.trim();

        if (!hid) {
            var act = accountStore && accountStore.activeAccount;
            hid = act ? act.account_id : "";
        }
        if (!hid) {
            modal.errorMessage = "Please enter or select a valid holding account ID.";
            return;
        }
        if (!did) {
            modal.errorMessage = "Please enter a valid Token Definition / Mint ID.";
            return;
        }
        if (!sym) {
            modal.errorMessage = "Token symbol is required (e.g. TEST).";
            return;
        }
        if (!nm) {
            nm = sym + " Token";
        }

        accountStore.registerTokenHolding(hid, did, sym, nm, modal.isPrivate, function (res) {
            if (res && res.ok) {
                accountStore.refreshTokens();
                modal.close();
            } else {
                modal.errorMessage = res && res.error ? String(res.error) : "Failed to register token holding.";
            }
        });
    }
}
