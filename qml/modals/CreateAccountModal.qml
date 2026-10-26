import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "Create New Account"
    subtitle: "Public Transparent or Shielded Zero-Knowledge"
    dialogWidth: 480
    dialogHeight: 380

    required property var accountStore

    property bool isPrivate: false
    property string errorMessage: ""

    Theme { id: theme }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        Text {
            Layout.fillWidth: true
            text: "Select account privacy model and provide an optional label for portfolio organization."
            color: theme.textSecondary
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeBody
            wrapMode: Text.WordWrap
        }

        // Privacy Model Selector (Zero-Icon Segmented Buttons)
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                Layout.fillWidth: true
                text: "Public Transparent"
                isPrimary: !modal.isPrivate
                onClicked: modal.isPrivate = false
            }

            Button {
                Layout.fillWidth: true
                text: "Shielded ZK Circuit"
                isPrimary: modal.isPrivate
                onClicked: modal.isPrivate = true
            }
        }

        PillBadge {
            text: modal.isPrivate ? "Full ZK-SNARK sender & receiver privacy" : "Standard public on-chain verifiable ledger account"
            badgeColor: modal.isPrivate ? theme.statusShielded : theme.statusPublic
        }

        TextField {
            id: labelInput
            Layout.fillWidth: true
            placeholder: modal.isPrivate ? "e.g. Private Savings" : "e.g. Daily Operations"
            text: modal.isPrivate ? "Shielded Account" : "Public Account"
            onAccepted: submitCreate()
        }

        Text {
            visible: modal.errorMessage.length > 0
            Layout.fillWidth: true
            text: modal.errorMessage
            color: theme.statusShielded
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
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
                text: "Create Account"
                isPrimary: true
                onClicked: submitCreate()
            }
        }
    }

    function submitCreate() {
        modal.errorMessage = "";
        var lbl = labelInput.text.trim();
        accountStore.createAccount(lbl, modal.isPrivate, function(res) {
            if (res && res.ok) {
                modal.close();
            } else {
                modal.errorMessage = res && res.error ? res.error : "Failed to create account";
            }
        });
    }
}
