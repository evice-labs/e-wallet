import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Card {
    id: testimonialCard

    required property var bridge
    required property var accountStore
    property var testimonialCtrl: null
    property var ledgerViewRef: null

    implicitHeight: 200
    title: "Testimonial & Broadcast"

    Connections {
        target: testimonialCtrl
        function onBroadcastSuccess(txHash, message) {
            if (testimonialCard.ledgerViewRef) {
                var previewText = message.length > 20 ? "\"" + message.substring(0, 18) + "...\"" : "\"" + message + "\"";
                testimonialCard.ledgerViewRef.addActivity(
                    testimonialCtrl ? testimonialCtrl.activeAuthor : "Active Account",
                    "zkVM Broadcast",
                    "Testimonials",
                    previewText,
                    "On-Chain Broadcast (0.1 LEZ)",
                    false
                );
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // Target Contract Info & Automatic Active Account Author Readout
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Target: Public/D7ADNV9oTPsS1qT5swbLsec4SZfsHodvJqkw4QqYGMBV"
                color: theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeTiny
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            // System-derived Author Affordance (Zero Manual Input)
            RowLayout {
                spacing: 4
                Text {
                    text: "Posting as:"
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTiny
                }
                Text {
                    text: testimonialCtrl ? testimonialCtrl.activeAuthor : (accountStore.activeAccount ? accountStore.activeAccount.label : "alice.lez")
                    color: theme.statusPublic
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                    font.weight: Font.DemiBold
                }
            }
        }

        // Single Intuitive Message Input Field
        TextField {
            id: msgInput
            Layout.fillWidth: true
            placeholder: "Say something on-chain..."
            text: testimonialCtrl ? testimonialCtrl.messageInput : ""
            onTextChanged: {
                if (testimonialCtrl && testimonialCtrl.messageInput !== text) {
                    testimonialCtrl.messageInput = text;
                }
            }
        }

        // Status Feedback Readout
        Text {
            visible: !!(testimonialCtrl && testimonialCtrl.statusMessage.length > 0)
            Layout.fillWidth: true
            text: testimonialCtrl ? testimonialCtrl.statusMessage : ""
            color: (testimonialCtrl && testimonialCtrl.isSuccessStatus) ? theme.statusSuccess : theme.accentOrange
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
            elide: Text.ElideRight
        }

        // Flexible Expanding Spacer
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // Skeuomorphic Divider
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // Footer Action Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: {
                    if (!testimonialCtrl) return "280 bytes remaining";
                    return testimonialCtrl.remainingBytes + " bytes remaining (" + testimonialCtrl.currentByteLength + "/280)";
                }
                color: (testimonialCtrl && testimonialCtrl.remainingBytes < 0) ? theme.statusDanger : theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
            }

            Item { Layout.fillWidth: true }

            Button {
                id: broadcastBtn
                text: (testimonialCtrl && testimonialCtrl.isBroadcasting) ? "Broadcasting..." : "Broadcast (0.1 LEZ)"
                isCompact: true
                isPrimary: true
                customHeight: 34
                enabled: testimonialCtrl !== null && testimonialCtrl.isValid
                onClicked: {
                    if (testimonialCtrl) {
                        testimonialCtrl.broadcast();
                    }
                }
            }
        }
    }
}
