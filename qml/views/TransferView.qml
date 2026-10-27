import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Card {
    id: transferCard

    required property var bridge
    required property var accountStore
    property var transferCtrl: null

    signal openUnlockModal()

    property string recipientInput: "bob.lez"
    property string amountInput: "10.00"
    property string transferMode: "public" // "public" | "shielded"
    property string transferStatus: ""
    property bool transferSuccess: false

    title: "QUICK TRANSFER"
    subtitle: "Instant Native & Zero-Knowledge Asset Transfer"

    ColumnLayout {
        width: parent.width
        spacing: 12

        // Recipient Field
        TextField {
            Layout.fillWidth: true
            label: "To"
            placeholder: "bob.lez / Address"
            text: transferCard.recipientInput
            onAccepted: transferCard.recipientInput = text
        }

        // Amount and Max Button
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            TextField {
                id: amtField
                Layout.fillWidth: true
                label: "Amount"
                placeholder: "10.00"
                text: transferCard.amountInput
                onAccepted: transferCard.amountInput = text
            }

            Button {
                text: "Max"
                isCompact: true
                Layout.alignment: Qt.AlignBottom
                onClicked: {
                    amtField.text = "100.00";
                    transferCard.amountInput = "100.00";
                }
            }
        }

        // Mode Selector (Public vs Shielded)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "Mode"
                color: theme.textSecondary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeSmall
            }

            Row {
                spacing: 8
                TabButton {
                    text: "Public"
                    isActive: transferCard.transferMode === "public"
                    onClicked: transferCard.transferMode = "public"
                }
                TabButton {
                    text: "Shielded"
                    isActive: transferCard.transferMode === "shielded"
                    onClicked: transferCard.transferMode = "shielded"
                }
            }
        }

        // Action Button
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: "Send Transfer"
                isPrimary: true
                Layout.fillWidth: true
                onClicked: {
                    if (bridge.isLocked) {
                        transferCard.transferStatus = "Error: Vault is locked. Please unlock first.";
                        transferCard.transferSuccess = false;
                        transferCard.openUnlockModal();
                        return;
                    }
                    transferCard.transferSuccess = true;
                    transferCard.transferStatus = "Transferred " + transferCard.amountInput + " LEZ to " + transferCard.recipientInput + " (" + transferCard.transferMode + ")";
                }
            }
        }

        // Status Feedback
        Text {
            visible: transferCard.transferStatus.length > 0
            text: transferCard.transferStatus
            color: transferCard.transferSuccess ? theme.statusSuccess : theme.statusDanger
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
