import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "Create New Account"
    dialogWidth: 480
    dialogHeight: 250

    required property var accountStore

    property bool isPrivate: false
    property string errorMessage: ""

    Theme { id: theme }

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // Privacy Model Selector
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                Layout.fillWidth: true
                text: "Public Unshielded"
                isPrimary: !modal.isPrivate
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
                onClicked: {
                    modal.isPrivate = true;
                    var count = (accountStore && accountStore.accounts) ? accountStore.accounts.length + 1 : 1;
                    labelInput.text = "Shielded Account " + count;
                }
            }
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
