import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "dApp Permission Request"
    dialogWidth: 540
    dialogHeight: 500

    required property var approvalManager

    Theme {
        id: theme
    }

    readonly property var prompt: approvalManager ? approvalManager.currentPrompt : null
    readonly property var sim: approvalManager ? approvalManager.simulatedEffect : null

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // CALLER IDENTITY & SECURITY VERIFICATION
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // DApp Icon
            Rectangle {
                id: dappIconBox
                readonly property string iconSrc: modal.prompt && modal.prompt.dapp_icon ? modal.prompt.dapp_icon.trim() : ""
                readonly property bool hasIcon: iconSrc.length > 0
                visible: hasIcon && (dappImg.status === Image.Ready || dappImg.status === Image.Loading) && dappImg.status !== Image.Error
                Layout.preferredWidth: visible ? 36 : 0
                Layout.preferredHeight: visible ? 36 : 0
                implicitWidth: visible ? 36 : 0
                implicitHeight: visible ? 36 : 0
                radius: theme.radiusSmall
                color: "transparent"
                clip: true

                Image {
                    id: dappImg
                    anchors.fill: parent
                    source: dappIconBox.hasIcon ? dappIconBox.iconSrc : ""
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    asynchronous: true
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: modal.prompt ? (modal.prompt.dapp_name || modal.prompt.dapp_identity || "External dApp") : "Connecting dApp"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeBody + 2
                    font.weight: Font.Bold
                }

                Text {
                    text: modal.prompt ? (modal.prompt.origin || (modal.prompt.session_id ? ("Session: " + modal.prompt.session_id) : "Origin Verified")) : ""
                    color: theme.textSecondary
                    font.family: theme.fontMono
                    font.pixelSize: theme.fontSizeSmall
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }

            // Source Verification Typography
            Text {
                text: {
                    var status = modal.approvalManager ? modal.approvalManager.verificationStatus : "Verified";
                    if (status === "Verified")
                        return "VERIFIED";
                    if (status === "Unverified")
                        return "UNVERIFIED SOURCE";
                    return "UNTRUSTED";
                }
                color: {
                    var status = modal.approvalManager ? modal.approvalManager.verificationStatus : "Verified";
                    if (status === "Verified")
                        return theme.statusSuccess;
                    if (status === "Unverified")
                        return theme.accentOrange;
                    return theme.statusDanger;
                }
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTiny
                font.weight: Font.Bold
            }
        }

        // Permission Scope Badge
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "REQUESTED SCOPE:"
                color: theme.textSecondary
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeTiny
            }

            Text {
                text: {
                    if (!modal.prompt)
                        return "GrantKind::Propose";
                    if (modal.prompt.grant_kind)
                        return modal.prompt.grant_kind;
                    var rk = modal.prompt.request_kind || "contract_call";
                    if (rk === "contract_call" || rk === "generic_call")
                        return "GrantKind::Propose (ContractCall)";
                    if (rk === "native_transfer")
                        return "GrantKind::Propose (NativeTransfer)";
                    if (rk === "token_transfer")
                        return "GrantKind::Propose (TokenTransfer)";
                    return "GrantKind::Propose";
                }
                color: theme.statusPublic
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTiny
                font.weight: Font.Bold
            }

            Item {
                Layout.fillWidth: true
            }
        }

        // PLAIN-LANGUAGE EFFECT SIMULATION
        Text {
            text: "TRANSACTION EFFECT SIMULATION"
            color: theme.textSecondary
            font.family: theme.fontMono
            font.pixelSize: theme.fontSizeSmall
        }

        InsetPanel {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(96, effectCol.implicitHeight + 24)

            ColumnLayout {
                id: effectCol
                anchors.fill: parent
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: modal.sim ? (modal.sim.effect || "Smart contract transaction proposal.") : "Simulating execution impact..."
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeBody
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: theme.borderSubtle
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "Gas Fee: " + (modal.sim ? (modal.sim.gas_fee || "0.001 LEZ") : "0.001 LEZ")
                        color: theme.textSecondary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "Net State Diff: " + (modal.sim ? (modal.sim.state_diff || "Pending") : "Pending")
                        color: theme.accentOrange
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                    }
                }
            }
        }

        // Informed Consent Warning
        Text {
            Layout.fillWidth: true
            text: "Security Advisory: Only authorize transactions from dApps you trust. Approving grants the caller permission to execute transactions within the simulated scope."
            color: theme.textMuted
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeTiny
            wrapMode: Text.WordWrap
        }

        Item {
            Layout.fillHeight: true
        }

        // Skeuomorphic Divider
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // ACTION BUTTONS
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Button {
                text: "Reject (0)"
                Layout.preferredWidth: 140
                isDestructive: true
                onClicked: {
                    if (modal.approvalManager) {
                        modal.approvalManager.reject(modal.prompt ? modal.prompt.request_id : null);
                    }
                    modal.close();
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "Authorize & Sign (1)"
                Layout.preferredWidth: 190
                isPrimary: true
                isFlat: true
                onClicked: {
                    if (modal.approvalManager) {
                        modal.approvalManager.approve(modal.prompt ? modal.prompt.request_id : null);
                    }
                    modal.close();
                }
            }
        }
    }
}
