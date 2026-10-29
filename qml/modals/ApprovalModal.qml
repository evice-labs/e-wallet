import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "dApp Permission Request"
    subtitle: "Informed Consent & Effect Simulation (LP-0023)"
    dialogWidth: 540
    dialogHeight: 460

    required property var approvalManager

    Theme { id: theme }

    readonly property var prompt: approvalManager ? approvalManager.currentPrompt : null
    readonly property var sim: approvalManager ? approvalManager.simulatedEffect : null

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        // CALLER IDENTITY & SECURITY VERIFICATION
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: modal.prompt ? (modal.prompt.dapp_name || "Unknown dApp") : "Connecting dApp"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeBody + 2
                    font.weight: Font.Bold
                }

                Text {
                    text: modal.prompt ? (modal.prompt.origin || "Origin Unknown") : ""
                    color: theme.textSecondary
                    font.family: theme.fontMono
                    font.pixelSize: theme.fontSizeSmall
                    elide: Text.ElideRight
                }
            }

            // LP-0023 Verification Typography
            Text {
                text: {
                    var status = modal.approvalManager ? modal.approvalManager.verificationStatus : "Verified";
                    if (status === "Verified") return "LP-0023 VERIFIED";
                    if (status === "Unverified") return "UNVERIFIED SOURCE";
                    return "UNTRUSTED";
                }
                color: {
                    var status = modal.approvalManager ? modal.approvalManager.verificationStatus : "Verified";
                    if (status === "Verified") return theme.statusSuccess;
                    if (status === "Unverified") return theme.accentOrange;
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
                text: modal.prompt ? (modal.prompt.grant_kind || "GrantKind::Propose") : "GrantKind::Read"
                color: theme.statusPublic
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTiny
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true }
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
            Layout.preferredHeight: 110

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 6

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

                    Item { Layout.fillWidth: true }

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

        Item { Layout.fillHeight: true }

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
                        modal.approvalManager.reject();
                    }
                    modal.close();
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Authorize & Sign (1)"
                Layout.preferredWidth: 190
                isPrimary: true
                onClicked: {
                    if (modal.approvalManager) {
                        modal.approvalManager.approve();
                    }
                    modal.close();
                }
            }
        }
    }
}
