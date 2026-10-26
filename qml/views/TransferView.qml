import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Item {
    id: view

    required property var bridge
    required property var accountStore
    required property var transferCtrl

    Theme { id: theme }

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentLayout.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        // Minimalist Scroll Indicator
        Rectangle {
            id: scrollIndicator
            anchors.right: parent.right
            anchors.rightMargin: 2
            y: flickable.visibleArea.yPosition * flickable.height
            width: 4
            height: Math.max(30, flickable.visibleArea.heightRatio * flickable.height)
            radius: 2
            color: theme.borderActive
            opacity: flickable.moving || flickable.dragging ? 0.7 : 0.3
            visible: flickable.visibleArea.heightRatio < 1.0
            z: 10
        }

        ColumnLayout {
            id: contentLayout
            width: parent.width - (scrollIndicator.visible ? 10 : 0)
            spacing: 16

            // Header Title
            RowLayout {
                Layout.fillWidth: true

                Column {
                    spacing: 2
                    Text {
                        text: "4-Way Asset Transfers"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeHero
                        font.weight: Font.Bold
                    }
                }

                Item { Layout.fillWidth: true }

                PillBadge {
                    text: "4-Way Privacy Matrix Supported"
                    badgeColor: theme.statusSuccess
                }
            }

            // Transfer Card Form
            Card {
                Layout.fillWidth: true
                title: "Transaction Composer"
                subtitle: "Compose native transfers or shield/unshield notes"

                ColumnLayout {
                    width: parent.width
                    height: implicitHeight
                    spacing: 14

                    // Privacy Direction Selector
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TabButton {
                            text: "Public → Public"
                            isActive: transferCtrl.transferMode === "pub_to_pub"
                            onClicked: transferCtrl.transferMode = "pub_to_pub"
                        }

                        TabButton {
                            text: "Public → Private (Shield)"
                            isActive: transferCtrl.transferMode === "pub_to_priv"
                            onClicked: transferCtrl.transferMode = "pub_to_priv"
                        }

                        TabButton {
                            text: "Private → Public (Unshield)"
                            isActive: transferCtrl.transferMode === "priv_to_pub"
                            onClicked: transferCtrl.transferMode = "priv_to_pub"
                        }

                        TabButton {
                            text: "Private → Private"
                            isActive: transferCtrl.transferMode === "priv_to_priv"
                            onClicked: transferCtrl.transferMode = "priv_to_priv"
                        }
                    }

                    // Source Account Inset
                    InsetPanel {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 64

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12

                            Column {
                                spacing: 2
                                Text {
                                    text: "FROM SENDER ACCOUNT"
                                    color: theme.textSecondary
                                    font.family: theme.fontMono
                                    font.pixelSize: theme.fontSizeSmall
                                }
                                Text {
                                    text: accountStore.activeAccount ? accountStore.activeAccount.label : "No Account Selected"
                                    color: theme.textPrimary
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontSizeBody
                                    font.weight: Font.Bold
                                }
                            }

                            Item { Layout.fillWidth: true }

                            PillBadge {
                                text: accountStore.activeAccount && accountStore.activeAccount.is_private ? "SHIELDED" : "PUBLIC"
                                badgeColor: accountStore.activeAccount && accountStore.activeAccount.is_private ? theme.statusShielded : theme.statusPublic
                            }

                            Text {
                                text: "Available: " + (accountStore.activeAccount ? accountStore.activeAccount.formatted_balance || "0.00" : "0.00") + " LEZ"
                                color: theme.textPrimary
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSizeBody
                                font.weight: Font.Bold
                            }
                        }
                    }

                    // Destination Address / LNS Name Input
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "RECIPIENT ADDRESS OR LNS NAME"
                                color: theme.textSecondary
                                font.family: theme.fontMono
                                font.pixelSize: theme.fontSizeSmall
                            }

                            Item { Layout.fillWidth: true }

                            PillBadge {
                                visible: transferCtrl.lnsStatus !== "idle"
                                text: transferCtrl.lnsMessage
                                badgeColor: transferCtrl.lnsStatus === "resolved" ? theme.statusSuccess : (transferCtrl.lnsStatus === "resolving" ? theme.statusPublic : theme.statusShielded)
                            }
                        }

                        TextField {
                            id: destField
                            Layout.fillWidth: true
                            placeholder: "e.g. alice.lez or Public/891ae258f92c..."
                            text: transferCtrl.destinationInput
                            onTextChanged: transferCtrl.destinationInput = text
                        }
                    }

                    // Amount Input & MAX Button
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Text {
                            text: "TRANSFER AMOUNT (LEZ)"
                            color: theme.textSecondary
                            font.family: theme.fontMono
                            font.pixelSize: theme.fontSizeSmall
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            TextField {
                                id: amtField
                                Layout.fillWidth: true
                                placeholder: "0.00"
                                text: transferCtrl.amountInput
                                onTextChanged: transferCtrl.amountInput = text
                            }

                            Button {
                                text: "MAX"
                                isCompact: true
                                isPrimary: false
                                onClicked: {
                                    if (accountStore.activeAccount) {
                                        amtField.text = accountStore.activeAccount.formatted_balance || "0.00";
                                    }
                                }
                            }
                        }
                    }

                    // Fee & Telemetry Readout
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: "Estimated Gas: " + transferCtrl.estimatedGas
                            color: theme.textMuted
                            font.family: theme.fontMono
                            font.pixelSize: theme.fontSizeSmall
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "Intent Binding: 32-Byte SHA-256 (Anti-TOCTOU)"
                            color: theme.textMuted
                            font.family: theme.fontMono
                            font.pixelSize: theme.fontSizeSmall
                        }
                    }

                    // Status Message Banner
                    Rectangle {
                        visible: statusText.text.length > 0
                        Layout.fillWidth: true
                        height: 38
                        radius: theme.radiusButton
                        color: isErrorBanner ? Qt.rgba(0.9, 0.2, 0.2, 0.15) : Qt.rgba(0.2, 0.8, 0.4, 0.15)
                        border.color: isErrorBanner ? theme.statusShielded : theme.statusSuccess
                        border.width: 1

                        property bool isErrorBanner: false

                        Text {
                            id: statusText
                            anchors.centerIn: parent
                            text: ""
                            color: parent.isErrorBanner ? theme.statusShielded : theme.statusSuccess
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeSmall
                            font.weight: Font.Bold
                        }
                    }

                    // Action Dispatch Button
                    RowLayout {
                        Layout.fillWidth: true

                        Button {
                            text: "Clear Fields"
                            isPrimary: false
                            onClicked: {
                                destField.text = "";
                                amtField.text = "";
                                statusText.text = "";
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Button {
                            text: transferCtrl.isSubmitting ? "Broadcasting..." : "Propose Transfer"
                            isPrimary: true
                            enabled: !transferCtrl.isSubmitting && !bridge.isLocked
                            onClicked: transferCtrl.submitTransfer()
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: transferCtrl
        function onTransferSuccess(requestId) {
            statusText.parent.isErrorBanner = false;
            statusText.text = "Transfer proposed successfully! Request ID: " + requestId;
        }
        function onTransferFailed(reason) {
            statusText.parent.isErrorBanner = true;
            statusText.text = "Transfer Failed: " + reason;
        }
    }
}
