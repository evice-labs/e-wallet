import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "Create New Account"
    dialogWidth: 500
    dialogHeight: 340

    required property var accountStore

    property bool isPrivate: false
    property string errorMessage: ""

    Theme {
        id: theme
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // Privacy Model Selector
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                Layout.fillWidth: true
                text: "Public Unshielded"
                isPrimary: !modal.isPrivate
                isCompact: true
                customHeight: 34
                onClicked: {
                    modal.isPrivate = false;
                    var count = (accountStore && accountStore.accounts) ? accountStore.accounts.length + 1 : 1;
                    labelInput.text = "Public Account " + count;
                }
            }

            Button {
                Layout.fillWidth: true
                text: "Private Shielded"
                isPrimary: modal.isPrivate
                isCompact: true
                customHeight: 34
                onClicked: {
                    modal.isPrivate = true;
                    var count = (accountStore && accountStore.accounts) ? accountStore.accounts.length + 1 : 1;
                    labelInput.text = "Shielded Account " + count;
                }
            }
        }

        // Informative Context Box explaining selected privacy model
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: privacyDescText.implicitHeight + 14
            radius: theme.radiusSmall
            color: modal.isPrivate ? Qt.rgba(theme.statusShielded.r, theme.statusShielded.g, theme.statusShielded.b, 0.10) : Qt.rgba(theme.statusPublic.r, theme.statusPublic.g, theme.statusPublic.b, 0.10)
            border.color: modal.isPrivate ? Qt.rgba(theme.statusShielded.r, theme.statusShielded.g, theme.statusShielded.b, 0.30) : Qt.rgba(theme.statusPublic.r, theme.statusPublic.g, theme.statusPublic.b, 0.30)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: modal.isPrivate ? theme.statusShielded : theme.statusPublic
                }

                Text {
                    id: privacyDescText
                    Layout.fillWidth: true
                    text: modal.isPrivate ? "Shielded accounts use zero-knowledge commitments and nullifiers. Balances and transaction history are completely confidential on-chain." : "Public accounts derive a transparent on-chain address. Balances and transaction amounts are visible on the public block explorer."
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTiny
                    wrapMode: Text.WordWrap
                }
            }
        }

        // Account Label Field Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "ACCOUNT LABEL"
                color: theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeTiny
                font.weight: Font.DemiBold
            }

            TextField {
                id: labelInput
                Layout.fillWidth: true
                placeholder: modal.isPrivate ? "e.g. Private Savings" : "e.g. Daily Operations"
                text: {
                    var count = (accountStore && accountStore.accounts) ? accountStore.accounts.length + 1 : 1;
                    return modal.isPrivate ? ("Shielded Account " + count) : ("Public Account " + count);
                }
                onAccepted: submitCreate()
            }
        }

        Text {
            visible: modal.errorMessage.length > 0
            Layout.fillWidth: true
            text: modal.errorMessage
            color: theme.statusDanger
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
            wrapMode: Text.WordWrap
        }

        Item {
            Layout.fillHeight: true
        }

        // Subtle Divider Line before Footer
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // Modal Action Buttons (Comfortably placed inside the card)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: "Cancel"
                isPrimary: false
                isCompact: true
                customHeight: 32
                onClicked: modal.close()
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "Create Account"
                isPrimary: true
                isCompact: true
                customHeight: 32
                onClicked: submitCreate()
            }
        }
    }

    function submitCreate() {
        modal.errorMessage = "";
        var lbl = labelInput.text.trim();
        accountStore.createAccount(lbl, modal.isPrivate, function (res) {
            if (res && res.ok) {
                modal.close();
            } else {
                modal.errorMessage = res && res.error ? res.error : "Failed to create account";
            }
        });
    }
}
