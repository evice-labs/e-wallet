import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Card {
    id: testimonialCard

    required property var bridge
    required property var accountStore
    property var ledgerViewRef: null

    implicitHeight: 195

    property string broadcastText: ""
    property string broadcastStatus: ""
    property bool isBroadcasting: false

    title: "Testimonial & Broadcast"

    headerRight: Component {
        RowLayout {
            spacing: 6
            Text {
                text: "ZK-PROGRAM 43466"
                color: theme.statusPublic
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTiny
                font.weight: Font.Bold
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // BODY: Target Program & On-Chain Message Input
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: "Target zkVM Contract: Public/D7ADNV9oTPsS1qT5swbLsec4SZfsHodvJqkw4QqYGMBV"
                color: theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeTiny
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            TextField {
                id: msgInput
                Layout.fillWidth: true
                placeholder: "Say something on-chain..."
                text: testimonialCard.broadcastText
                onAccepted: testimonialCard.broadcastText = text
            }

            Text {
                visible: testimonialCard.broadcastStatus.length > 0
                text: testimonialCard.broadcastStatus
                color: theme.statusSuccess
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeSmall
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        // FLEXIBLE EXPANDING SPACER (absorbs vertical stretch)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // STATIC FOOTER: Character Counter & Broadcast Button
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: (280 - msgInput.text.length) + " chars remaining"
                color: (280 - msgInput.text.length) < 0 ? theme.statusDanger : theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
            }

            Item { Layout.fillWidth: true }

            Button {
                text: testimonialCard.isBroadcasting ? "Broadcasting..." : "Broadcast (0.1 LEZ)"
                isCompact: true
                isPrimary: true
                enabled: msgInput.text.trim().length > 0 && (280 - msgInput.text.length) >= 0 && !testimonialCard.isBroadcasting
                onClicked: {
                    var msg = msgInput.text.trim();
                    testimonialCard.isBroadcasting = true;
                    testimonialCard.broadcastStatus = "Broadcasting to zkVM contract...";
                    bridge.invoke("proposeTransaction", [
                        "Public/D7ADNV9oTPsS1qT5swbLsec4SZfsHodvJqkw4QqYGMBV",
                        msg,
                        "4f793e86-5a23-4d20-969b-b993291caf59"
                    ], function(res) {
                        testimonialCard.isBroadcasting = false;
                        if (res && res.ok) {
                            var shortHash = res.tx_hash ? (res.tx_hash.substring(0, 10) + "..." + res.tx_hash.substring(res.tx_hash.length - 6)) : "0x9f53...af184";
                            testimonialCard.broadcastStatus = "Broadcasted to Logos zkVM! Tx: " + shortHash;
                            msgInput.text = "";
                            if (testimonialCard.ledgerViewRef) {
                                var previewText = msg.length > 20 ? "\"" + msg.substring(0, 18) + "...\"" : "\"" + msg + "\"";
                                testimonialCard.ledgerViewRef.addActivity("Testimonial", "Ledger", "Testimonials", previewText, "On-Chain Broadcast (0.1 LEZ)", false);
                            }
                        } else {
                            testimonialCard.broadcastStatus = "Broadcast error: " + (res && res.error ? res.error : "Unknown");
                        }
                    });
                }
            }
        }

        Text {
            visible: testimonialCard.broadcastStatus.length > 0
            text: testimonialCard.broadcastStatus
            color: theme.statusSuccess
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
}
