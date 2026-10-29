import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "Account Details & Keys"
    subtitle: account ? (account.is_private ? "Shielded ZK Circuit Account" : "Public Transparent Account") : ""
    dialogWidth: 560
    dialogHeight: 500

    required property var accountStore
    property var account: null

    property string activeTab: "overview" // "overview" | "keys"
    property bool keysRevealed: false
    property string copyStatus: ""

    Theme { id: theme }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // ── Header Privacy Badge & Balance ────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: (modal.account && modal.account.is_private ? "SHIELDED NOTE STORAGE" : "PUBLIC LEDGER KEY")
                color: modal.account && modal.account.is_private ? theme.statusShielded : theme.statusPublic
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTiny
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true }

            Text {
                text: (modal.account ? modal.account.formatted_balance || "0.00" : "0.00") + " LEZ"
                color: theme.textPrimary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTitle + 4
                font.weight: Font.Bold
            }
        }

        // ── Tab Switcher (Overview vs Key Export) ──────────────
        Row {
            spacing: 8
            TabButton {
                text: "Overview & Address"
                isActive: modal.activeTab === "overview"
                onClicked: modal.activeTab = "overview"
            }
            TabButton {
                text: "Export Cryptographic Keys"
                isActive: modal.activeTab === "keys"
                onClicked: modal.activeTab = "keys"
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // ── TAB 1: OVERVIEW & ADDRESS ─────────────────────────
        ColumnLayout {
            visible: modal.activeTab === "overview"
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "ACCOUNT IDENTIFIER (32-BYTE ADDRESS / PDA)"
                color: theme.textSecondary
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
            }

            InsetPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 60

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 24
                    text: modal.account ? modal.account.account_id : ""
                    color: theme.textPrimary
                    font.family: theme.fontMono
                    font.pixelSize: theme.fontSizeSmall
                    wrapMode: Text.WrapAnywhere
                }
            }

            Text {
                text: "ACCOUNT LABEL"
                color: theme.textSecondary
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextField {
                    id: labelField
                    Layout.fillWidth: true
                    text: modal.account ? modal.account.label || "" : ""
                }

                Button {
                    text: "Save Label"
                    isPrimary: true
                    isCompact: true
                    onClicked: {
                        if (modal.account) {
                            accountStore.setAccountLabel(modal.account.account_id, labelField.text, modal.account.is_private, function(res) {
                                if (res && res.ok) {
                                    modal.copyStatus = "Label updated successfully";
                                }
                            });
                        }
                    }
                }
            }
        }

        // ── TAB 2: KEY EXPORT & SECRET INSPECTOR ──────────────
        ColumnLayout {
            visible: modal.activeTab === "keys"
            Layout.fillWidth: true
            spacing: 12

            Text {
                Layout.fillWidth: true
                text: "Security Notice: Never share secret spend keys or viewing credentials. Anyone with access to these keys can monitor or spend assets associated with this account."
                color: theme.accentOrange
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Secret Key Exposure:"
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: modal.keysRevealed ? "Hide Keys" : "Reveal Credentials"
                    isCompact: true
                    isDestructive: modal.keysRevealed
                    onClicked: modal.keysRevealed = !modal.keysRevealed
                }
            }

            InsetPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 120

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    Text {
                        text: modal.account && modal.account.is_private ? "SHIELDED SPEND COMMITMENT & VIEW KEY:" : "PUBLIC KEY & VERIFICATION CREDENTIAL:"
                        color: theme.textMuted
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeTiny
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (!modal.keysRevealed) return "••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••";
                            if (!modal.account) return "";
                            return modal.account.account_id;
                        }
                        color: modal.keysRevealed ? theme.textPrimary : theme.textMuted
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                        wrapMode: Text.WrapAnywhere
                    }

                    Text {
                        text: "DERIVATION / KEYSTORE ENCRYPTION: BIP-39 (Argon2id + AES-256-GCM)"
                        color: theme.statusSuccess
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeTiny
                    }
                }
            }
        }

        // ── Status Telemetry / Feedback ───────────────────────
        Text {
            visible: modal.copyStatus.length > 0
            text: modal.copyStatus
            color: theme.statusSuccess
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
        }

        Item { Layout.fillHeight: true }

        // ── Action Buttons ────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            Button {
                text: "Copy Address"
                isPrimary: false
                onClicked: {
                    if (modal.account) {
                        copyHelper.text = modal.account.account_id;
                        copyHelper.selectAll();
                        copyHelper.copy();
                        modal.copyStatus = "Address copied to clipboard!";
                    }
                }
            }

            Button {
                visible: modal.activeTab === "keys" && modal.keysRevealed
                text: "Copy Key"
                isPrimary: false
                onClicked: {
                    if (modal.account) {
                        copyHelper.text = modal.account.account_id;
                        copyHelper.selectAll();
                        copyHelper.copy();
                        modal.copyStatus = "Credential copied to clipboard!";
                    }
                }
            }

            TextEdit {
                id: copyHelper
                visible: false
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Done"
                isPrimary: true
                onClicked: {
                    modal.keysRevealed = false;
                    modal.copyStatus = "";
                    modal.close();
                }
            }
        }
    }
}
