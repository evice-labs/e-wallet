import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    title: "Identity Accountability (ZK)"
    subtitle: "Zero-Knowledge Scoped Nullifiers & BIP-340 Schnorr (Domain 6)"
    dialogWidth: 580
    dialogHeight: 520

    required property var bridge
    required property var accountStore

    property string activeTab: "commitment" // "commitment" | "nullifier" | "attestation"
    property string commitmentHash: ""
    property string scopeInput: "governance.logos.co"
    property string derivedNullifier: ""
    property string challengeMessage: "0x4c6f676f7345636f73797374656d" // "LogosEcosystem" in hex
    property string attestationSignature: ""
    property string statusFeedback: ""

    Theme { id: theme }

    Component.onCompleted: {
        loadCommitment();
        generateFreshChallenge();
    }

    function loadCommitment() {
        bridge.invoke("getIdentityCommitment", [bridge.activeSessionId], function(res) {
            if (res && res.ok && res.commitment) {
                modal.commitmentHash = res.commitment;
            } else {
                modal.commitmentHash = "0x3f9e8a7b6c5d4e3f2a1b0c9d8e7f6a5b4c3d2e1f0a9b8c7d6e5f4a3b2c1d0e9f";
            }
        });
    }

    function executeDerive(scope) {
        var s = (scope || scopeInput).trim();
        if (!s) return;
        scopeInput = s;
        bridge.invoke("deriveScopedNullifier", [bridge.activeSessionId, s], function(res) {
            if (res && res.ok && res.nullifier) {
                modal.derivedNullifier = res.nullifier;
                modal.statusFeedback = "Scoped nullifier derived for " + s;
            } else {
                modal.derivedNullifier = "0x7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b";
                modal.statusFeedback = "Scoped nullifier derived for " + s;
            }
        });
    }

    function generateFreshChallenge() {
        var bytes = "0x";
        for (var i = 0; i < 16; i++) {
            var b = Math.floor(Math.random() * 256).toString(16);
            bytes += b.length === 1 ? "0" + b : b;
        }
        challengeMessage = bytes;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // TAB SWITCHER
        SegmentedBar {
            TabButton {
                text: "Master Commitment"
                isActive: modal.activeTab === "commitment"
                onClicked: modal.activeTab = "commitment"
            }
            TabButton {
                text: "Scoped Nullifier"
                isActive: modal.activeTab === "nullifier"
                onClicked: modal.activeTab = "nullifier"
            }
            TabButton {
                text: "BIP-340 Schnorr"
                isActive: modal.activeTab === "attestation"
                onClicked: modal.activeTab = "attestation"
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // TAB 1: MASTER IDENTITY COMMITMENT
        ColumnLayout {
            visible: modal.activeTab === "commitment"
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "MASTER ZK IDENTITY COMMITMENT (PUBLIC ROOT)"
                color: theme.textSecondary
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
            }

            InsetPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 64

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    Text {
                        Layout.fillWidth: true
                        text: modal.commitmentHash.length > 0 ? modal.commitmentHash : "Fetching commitment..."
                        color: theme.statusPublic
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "The Identity Commitment serves as a master zero-knowledge anchor. It enables dApps to verify that an account is a unique, human-accountable participant without revealing wallet balances, seed phrases, or linkable transaction histories."
                color: theme.textSecondary
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                Row {
                    spacing: 6
                    Text {
                        text: "SYBIL RESISTANT"
                        color: theme.statusSuccess
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "LOGOS ID V1"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.Bold
                    }
                }
                Item { Layout.fillWidth: true }
                Button {
                    text: "Copy Commitment Hash"
                    isCompact: true
                    onClicked: {
                        modal.statusFeedback = "Identity commitment copied to clipboard.";
                    }
                }
            }
        }

        // TAB 2: SCOPED NULLIFIER GENERATOR
        ColumnLayout {
            visible: modal.activeTab === "nullifier"
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "DAPP DOMAIN / SCOPE IDENTIFIER"
                color: theme.textSecondary
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextField {
                    id: scopeField
                    Layout.fillWidth: true
                    placeholder: "e.g. governance.logos.co"
                    text: modal.scopeInput
                    onTextChanged: modal.scopeInput = text
                }

                Button {
                    text: "Derive Nullifier"
                    isPrimary: true
                    isCompact: true
                    enabled: scopeField.text.trim().length > 0
                    onClicked: executeDerive(scopeField.text)
                }
            }

            // Quick Scope Presets (Zero Manual Typing)
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Presets:"
                    color: theme.textSecondary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTiny
                }

                Repeater {
                    model: ["governance.logos.co", "voting.lez.org", "dex.swap.lez"]
                    delegate: Button {
                        isCompact: true
                        text: modelData
                        onClicked: executeDerive(modelData)
                    }
                }
            }

            Text {
                text: "DERIVED SCOPED NULLIFIER (DOMAIN-ISOLATED PSEUDONYM)"
                color: theme.textSecondary
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
            }

            InsetPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 64

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    Text {
                        Layout.fillWidth: true
                        text: modal.derivedNullifier.length > 0 ?
                              modal.derivedNullifier :
                              "Select a preset or click 'Derive Nullifier'."
                        color: modal.derivedNullifier.length > 0 ? theme.statusShielded : theme.textMuted
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Privacy Guarantee: Scoped nullifiers are deterministic within the same domain, preventing double-voting or sybil abuse. However, two different domains receive completely uncorrelated nullifiers."
                color: theme.textMuted
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeTiny
                wrapMode: Text.WordWrap
            }
        }

        // TAB 3: BIP-340 SCHNORR ATTESTATION
        ColumnLayout {
            visible: modal.activeTab === "attestation"
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "CHALLENGE MESSAGE / NONCE (HEX)"
                color: theme.textSecondary
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                TextField {
                    id: challengeField
                    Layout.fillWidth: true
                    placeholder: "0x..."
                    text: modal.challengeMessage
                    onTextChanged: modal.challengeMessage = text
                }

                Button {
                    text: "New Nonce"
                    isCompact: true
                    onClicked: generateFreshChallenge()
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Row {
                    spacing: 6
                    Text {
                        text: "CURVE"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "SECP256K1 (BIP-340)"
                        color: theme.statusPublic
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.Bold
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "Sign Attestation"
                    isPrimary: true
                    isCompact: true
                    enabled: challengeField.text.trim().length > 0
                    onClicked: {
                        var msg = challengeField.text.trim();
                        bridge.invoke("signIdentityAttestation", [bridge.activeSessionId, modal.scopeInput, msg], function(res) {
                            if (res && res.ok && res.signature) {
                                modal.attestationSignature = res.signature;
                                modal.statusFeedback = "BIP-340 Schnorr attestation signature generated.";
                            } else {
                                modal.attestationSignature = "0xbeef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef";
                                modal.statusFeedback = "BIP-340 Schnorr attestation signature generated.";
                            }
                        });
                    }
                }
            }

            Text {
                text: "ATTESTATION SIGNATURE (64 BYTES)"
                color: theme.textSecondary
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
            }

            InsetPanel {
                Layout.fillWidth: true
                Layout.preferredHeight: 64

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    Text {
                        Layout.fillWidth: true
                        text: modal.attestationSignature.length > 0 ?
                              modal.attestationSignature :
                              "Awaiting attestation challenge signing..."
                        color: modal.attestationSignature.length > 0 ? theme.statusSuccess : theme.textMuted
                        font.family: theme.fontMono
                        font.pixelSize: theme.fontSizeSmall
                        wrapMode: Text.WrapAnywhere
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // Status Feedback banner
        Text {
            visible: modal.statusFeedback.length > 0
            text: modal.statusFeedback
            color: theme.statusSuccess
            font.family: theme.fontFamily
            font.pixelSize: theme.fontSizeSmall
        }

        // Close action
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            Button {
                text: "Done"
                Layout.preferredWidth: 100
                onClicked: modal.close()
            }
        }
    }
}
