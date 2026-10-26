import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "Account Details & Keys"
    subtitle: account ? (account.is_private ? "Shielded ZK Circuit Account" : "Public Transparent Account") : ""
    dialogWidth: 540
    dialogHeight: 440

    required property var accountStore
    property var account: null

    Theme { id: theme }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            PillBadge {
                text: modal.account && modal.account.is_private ? "Shielded Note Storage" : "Public Ledger Key"
                badgeColor: modal.account && modal.account.is_private ? theme.statusShielded : theme.statusPublic
            }

            Item { Layout.fillWidth: true }

            Text {
                text: (modal.account ? modal.account.formatted_balance || "0.00" : "0.00") + " LEZ"
                color: theme.textPrimary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeHero
                font.weight: Font.Bold
            }
        }

        Text {
            text: "ACCOUNT IDENTIFIER (32-BYTE ADDRESS)"
            color: theme.textSecondary
            font.family: theme.fontMono
            font.pixelSize: theme.fontSizeSmall
        }

        InsetPanel {
            Layout.fillWidth: true
            Layout.preferredHeight: 64

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
                                modal.close();
                            }
                        });
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true

            Button {
                text: "Copy Address"
                isPrimary: false
                onClicked: {
                    if (modal.account) {
                        // QML Clipboard copy
                        copyHelper.text = modal.account.account_id;
                        copyHelper.selectAll();
                        copyHelper.copy();
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
                isPrimary: false
                onClicked: modal.close()
            }
        }
    }
}
