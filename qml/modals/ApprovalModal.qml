import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "dApp Permission Request"
    dialogWidth: 500
    dialogHeight: contentCol ? Math.max(400, Math.round(contentCol.implicitHeight + 109)) : 460

    required property var approvalManager

    Theme {
        id: theme
    }

    readonly property var prompt: approvalManager ? approvalManager.currentPrompt : null
    readonly property var sim: approvalManager ? approvalManager.simulatedEffect : null
    property bool _actionHandled: false

    onClosed: {
        if (!_actionHandled && approvalManager && approvalManager.isPromptActive && modal.prompt && modal.prompt.request_id) {
            approvalManager.reject(modal.prompt.request_id);
        }
        _actionHandled = false;
    }

    Connections {
        target: modal.approvalManager
        function onPromptReceived() {
            modal._actionHandled = false;
        }
        function onPromptDismissed(reqId) {
            if (modal.visible && modal.prompt && modal.prompt.request_id === reqId) {
                modal._actionHandled = true;
                modal.close();
            }
        }
    }

    function scopeLabel() {
        if (!modal.prompt)
            return "Propose";
        var rk = modal.prompt.request_kind || "contract_call";
        if (rk === "native_transfer")
            return "Propose • Native Transfer";
        if (rk === "token_transfer")
            return "Propose • Token Transfer";
        return "Propose • Contract Call";
    }

    function targetLabel() {
        if (!modal.prompt)
            return "-";
        var target = modal.prompt.program_id || modal.prompt.program || modal.prompt.to || "";
        if (!target)
            return "-";
        var clean = String(target).trim();
        if (clean.toLowerCase().startsWith("public/") || clean.toLowerCase().startsWith("private/"))
            return clean;
        return "Public/" + clean;
    }

    ColumnLayout {
        id: contentCol
        anchors.fill: parent
        spacing: 12

        // 1. CALLER IDENTITY & VERIFICATION STATUS
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    Layout.fillWidth: true
                    text: modal.prompt ? (modal.prompt.dapp_name || modal.prompt.dapp_identity || "External dApp") : "External dApp"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeBody + 2
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    text: {
                        var status = modal.approvalManager ? modal.approvalManager.verificationStatus : "Verified";
                        if (status === "Verified")
                            return "VERIFIED";
                        if (status === "Unverified")
                            return "UNVERIFIED";
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
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Text {
                text: modal.prompt ? (modal.prompt.origin || (modal.prompt.session_id ? ("Session: " + modal.prompt.session_id) : "")) : ""
                visible: text.length > 0
                color: theme.textSecondary
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeTiny
                elide: Text.ElideMiddle
                Layout.fillWidth: true
            }
        }

        // 2. REQUEST SUMMARY CARD
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: actionCardCol.implicitHeight + 24
            radius: theme.radiusCard
            color: theme.bgSurface
            border.color: "transparent"
            border.width: 0

            ColumnLayout {
                id: actionCardCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                    text: "Action"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                Text {
                    Layout.fillWidth: true
                    text: modal.sim ? (modal.sim.effect || "Smart contract execution") : "Simulating execution..."
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }

                Text {
                    visible: modal.targetLabel() !== "-"
                    text: (modal.prompt && modal.prompt.request_kind === "native_transfer") ? "Recipient" : "Target Program"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeSmall
                    font.weight: Font.Medium
                }

                Text {
                    visible: modal.targetLabel() !== "-"
                    Layout.fillWidth: true
                    text: modal.targetLabel()
                    color: theme.textSecondary
                    font.family: theme.fontMono
                    font.pixelSize: theme.fontSizeSmall
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        // 3. EXECUTION TELEMETRY CARD
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: telemetryCol.implicitHeight + 24
            radius: theme.radiusCard
            color: theme.bgSurface
            border.color: "transparent"
            border.width: 0

            ColumnLayout {
                id: telemetryCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 7

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Requested Scope"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: modal.scopeLabel()
                        color: theme.statusPublic
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                        font.weight: Font.DemiBold
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Simulation"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        Layout.maximumWidth: 260
                        elide: Text.ElideRight
                        text: modal.sim ? (modal.sim.state_diff || "Pending") : "Pending"
                        color: theme.accentOrange
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "Estimated Gas"
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }
                    Item {
                        Layout.fillWidth: true
                    }
                    Text {
                        text: modal.sim ? (modal.sim.gas_fee || "~275,640 units") : "~275,640 units"
                        color: theme.textSecondary
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                    }
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Only authorize transactions from dApps you trust."
            color: theme.textMuted
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeTiny
            wrapMode: Text.WordWrap
        }

        // ACTION BUTTONS
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 12

            Button {
                text: "Reject"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                isDestructive: true
                onClicked: {
                    modal._actionHandled = true;
                    if (modal.approvalManager) {
                        modal.approvalManager.reject(modal.prompt ? modal.prompt.request_id : null);
                    }
                    modal.close();
                }
            }

            Button {
                text: "Authorize & Sign"
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                isPrimary: true
                isFlat: true
                onClicked: {
                    modal._actionHandled = true;
                    if (modal.approvalManager) {
                        modal.approvalManager.approve(modal.prompt ? modal.prompt.request_id : null);
                    }
                    modal.close();
                }
            }
        }
    }
}
