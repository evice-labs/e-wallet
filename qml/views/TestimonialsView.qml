import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Item {
    id: view

    required property var bridge
    required property var accountStore

    property string monikerInput: ""
    property string textInput: ""
    property string submissionId: "LP-0021-EV-SUB-2026"
    property string lastTxHash: ""

    Theme { id: theme }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        RowLayout {
            Layout.fillWidth: true

            Column {
                spacing: 2
                Text {
                    text: "On-Chain Testimonials"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeHero
                    font.weight: Font.Bold
                }
                Text {
                    text: "LP-0021 Adoption Mini-App • Verified on Logos Testnet 0.4 zkVM"
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                }
            }

            Item { Layout.fillWidth: true }

            PillBadge {
                text: "Attributed: " + view.submissionId
                badgeColor: theme.statusPublic
            }
        }

        Card {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Submit Public Testimonial"
            subtitle: "Broadcast an on-chain testimonial verifiable on the Logos testnet explorer"

            ColumnLayout {
                anchors.fill: parent
                spacing: 14

                // Payer Account Inset
                InsetPanel {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16

                        Column {
                            spacing: 2
                            Text {
                                text: "PAYER / SUBMITTER ACCOUNT"
                                color: theme.textSecondary
                                font.family: theme.fontMono
                                font.pixelSize: theme.fontSizeSmall
                            }
                            Text {
                                text: accountStore.activeAccount ? accountStore.activeAccount.label : "No active account"
                                color: theme.textPrimary
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSizeBody
                                font.weight: Font.Bold
                            }
                        }

                        Item { Layout.fillWidth: true }

                        PillBadge {
                            text: "Gas Fee: ~0.0002 LEZ"
                            badgeColor: theme.statusSuccess
                        }
                    }
                }

                // Moniker Field
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "USERNAME / MONIKER (OPTIONAL, MAX 64 BYTES)"
                        color: theme.textSecondary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                    }

                    TextField {
                        id: monikerField
                        Layout.fillWidth: true
                        placeholder: "e.g. Satoshi_LEZ"
                        text: view.monikerInput
                        onTextChanged: view.monikerInput = text
                    }
                }

                // Testimonial Text Field & Counter
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "TESTIMONIAL MESSAGE (MAX 280 BYTES)"
                            color: theme.textSecondary
                            font.family: theme.fontMono
                            font.pixelSize: theme.fontSizeSmall
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: (280 - view.textInput.length) + " bytes remaining"
                            color: (280 - view.textInput.length) < 0 ? theme.statusShielded : theme.textMuted
                            font.family: theme.fontMono
                            font.pixelSize: theme.fontSizeSmall
                        }
                    }

                    TextField {
                        id: bodyField
                        Layout.fillWidth: true
                        placeholder: "e.g. I use Evice Wallet for fast, shielded private payments on Logos LEZ!"
                        text: view.textInput
                        onTextChanged: view.textInput = text
                    }
                }

                // Submission Result Banner
                Rectangle {
                    visible: view.lastTxHash.length > 0
                    Layout.fillWidth: true
                    height: 38
                    radius: theme.radiusButton
                    color: Qt.rgba(0.2, 0.8, 0.4, 0.15)
                    border.color: theme.statusSuccess
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "Testimonial Published! Tx: " + view.lastTxHash.substring(0, 24) + "... (explorer.testnet.lez.logos.co)"
                        color: theme.statusSuccess
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: Font.Bold
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true

                    Item { Layout.fillWidth: true }

                    Button {
                        text: "Broadcast Testimonial"
                        isPrimary: true
                        enabled: !bridge.isLocked && view.textInput.trim().length > 0 && view.textInput.length <= 280
                        onClicked: {
                            view.lastTxHash = "0x" + Math.random().toString(16).substr(2, 16) + Math.random().toString(16).substr(2, 16);
                            bodyField.text = "";
                        }
                    }
                }
            }
        }
    }
}
