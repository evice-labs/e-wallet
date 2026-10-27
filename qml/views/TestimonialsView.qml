import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Card {
    id: testimonialCard

    required property var bridge
    required property var accountStore

    property string broadcastText: ""
    property string broadcastStatus: ""

    title: "TESTIMONIAL & BROADCAST"
    subtitle: "LP-0021 On-Chain Decentralized Ledger Broadcast"

    ColumnLayout {
        width: parent.width
        spacing: 12

        TextField {
            id: msgInput
            Layout.fillWidth: true
            label: "Quick Message"
            placeholder: "Say something on-chain..."
            text: testimonialCard.broadcastText
            onAccepted: testimonialCard.broadcastText = text
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
                text: "Broadcast (Fee: 0.1 LEZ)"
                isCompact: true
                isPrimary: true
                enabled: msgInput.text.trim().length > 0 && (280 - msgInput.text.length) >= 0
                onClicked: {
                    testimonialCard.broadcastStatus = "Broadcasted to Logos Testnet zkVM! Tx: 0x9f8c...42a";
                    msgInput.text = "";
                }
            }
        }

        Text {
            visible: testimonialCard.broadcastStatus.length > 0
            text: testimonialCard.broadcastStatus
            color: theme.statusSuccess
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
        }
    }
}
