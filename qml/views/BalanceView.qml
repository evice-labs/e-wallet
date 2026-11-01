import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

Card {
    id: balanceCard

    required property var bridge
    required property var accountStore

    implicitHeight: 295

    signal openCreateAccount()
    signal openSettingsModal()
    signal openUnlockModal()
    signal openProfileModal()
    signal triggerDappPreview()

    property var approvalManager: null
    property bool isCascadeExpanded: false
    property string activeAssetTab: "native" // "native" | "tokens"

    function getSecondaryAccount() {
        if (!accountStore || !accountStore.accounts || accountStore.accounts.length < 2) return null;
        for (var i = 0; i < accountStore.accounts.length; i++) {
            var acc = accountStore.accounts[i];
            if (!accountStore.activeAccount || acc.account_id !== accountStore.activeAccount.account_id) {
                return acc;
            }
        }
        return null;
    }

    z: 1
    title: "Your Balance"

    headerRight: Component {
        RowLayout {
            spacing: 12

            // Friendly Brief Greeting & Status
            ColumnLayout {
                spacing: 1
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

                Text {
                    Layout.alignment: Qt.AlignRight
                    text: {
                        var name = accountStore.activeAccount && accountStore.activeAccount.label ? accountStore.activeAccount.label : "alice.lez";
                        return "Hola, " + name;
                    }
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeBody
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 5

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: bridge.isLocked ? theme.accentOrange : theme.statusSuccess
                    }

                    Text {
                        text: {
                            if (bridge.isLocked) return "Vault Locked";
                            var isPriv = accountStore.activeAccount && accountStore.activeAccount.is_private;
                            var count = (accountStore.accounts && accountStore.accounts.length) || 1;
                            return (isPriv ? "Shielded ZK" : "Public") + (count > 1 ? " • " + count + " Accounts" : "");
                        }
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                    }
                }
            }

            // Cascaded Avatar Container
            Item {
                id: cascadedAvatarContainer
                width: balanceCard.isCascadeExpanded ? 80 : 46
                height: 38
                Layout.preferredWidth: width
                Layout.preferredHeight: height

                Behavior on width {
                    NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                }

                readonly property var secondaryAcc: balanceCard.getSecondaryAccount()

                // BACK RECTANGLE: Cascaded secondary action
                Rectangle {
                    id: backCascadeItem
                    z: 1
                    width: 34
                    height: 34
                    radius: 17
                    anchors.verticalCenter: parent.verticalCenter
                    x: balanceCard.isCascadeExpanded ? 42 : 10

                    Behavior on x {
                        NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                    }

                    color: cascadedAvatarContainer.secondaryAcc ?
                           (backHoverArea.containsMouse ? "#2a4365" : "#1e293b") :
                           (backHoverArea.containsMouse ? theme.bgSurfaceSubtle : "#252b42")
                    border.color: cascadedAvatarContainer.secondaryAcc ?
                                  (backHoverArea.containsMouse ? theme.statusPublic : "#3b4261") :
                                  (backHoverArea.containsMouse ? theme.borderActive : theme.borderSubtle)
                    border.width: 1.5

                    // Secondary Profile Exists -> Show Initial Letter + ⇄ badge
                    Item {
                        anchors.fill: parent
                        visible: cascadedAvatarContainer.secondaryAcc !== null

                        Text {
                            anchors.centerIn: parent
                            text: cascadedAvatarContainer.secondaryAcc && cascadedAvatarContainer.secondaryAcc.label ?
                                  cascadedAvatarContainer.secondaryAcc.label.substring(0, 1).toUpperCase() : "2"
                            font.family: theme.fontFamily
                            font.bold: true
                            font.pixelSize: 14
                            color: theme.statusPublic
                        }

                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: theme.statusPublic
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.bottomMargin: -1
                            anchors.rightMargin: -1

                            Text {
                                anchors.centerIn: parent
                                text: "⇄"
                                font.pixelSize: 7
                                color: "#0d1117"
                                font.bold: true
                            }
                        }
                    }

                    // Single Profile -> Show "+" to add new account
                    Item {
                        anchors.fill: parent
                        visible: cascadedAvatarContainer.secondaryAcc === null

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            font.family: theme.fontFamily
                            font.bold: true
                            font.pixelSize: 18
                            color: backHoverArea.containsMouse ? theme.textPrimary : theme.textMuted
                        }
                    }

                    MouseArea {
                        id: backHoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (cascadedAvatarContainer.secondaryAcc) {
                                accountStore.selectAccount(cascadedAvatarContainer.secondaryAcc);
                                balanceCard.isCascadeExpanded = false;
                            } else {
                                balanceCard.isCascadeExpanded = false;
                                balanceCard.openCreateAccount();
                            }
                        }
                    }
                }

                // FRONT CIRCLE: Active Profile Icon
                Rectangle {
                    id: frontAvatarItem
                    z: 2
                    width: 36
                    height: 36
                    radius: 18
                    anchors.verticalCenter: parent.verticalCenter
                    x: 0
                    color: theme.bgSurface
                    border.color: frontHoverArea.containsMouse ? theme.borderActive : theme.borderCard
                    border.width: 1.5

                    scale: frontHoverArea.pressed ? 0.94 : (frontHoverArea.containsMouse ? 1.05 : 1.0)
                    Behavior on scale {
                        NumberAnimation { duration: 120 }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: {
                            var lbl = accountStore.activeAccount && accountStore.activeAccount.label ? accountStore.activeAccount.label : "alice.lez";
                            return lbl.substring(0, 1).toUpperCase();
                        }
                        font.family: theme.fontFamily
                        font.bold: true
                        font.pixelSize: 15
                        color: theme.textPrimary
                    }

                    // Notification Badge for pending dApp authorization queue
                    Rectangle {
                        id: notifBadge
                        visible: approvalManager && approvalManager.pendingRequests && approvalManager.pendingRequests.length > 0
                        width: 15
                        height: 15
                        radius: 7.5
                        color: theme.accentOrange
                        border.color: theme.bgSurface
                        border.width: 1.5
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: -3
                        anchors.rightMargin: -3
                        z: 10

                        Text {
                            anchors.centerIn: parent
                            text: approvalManager ? (approvalManager.pendingRequests.length > 9 ? "9+" : approvalManager.pendingRequests.length) : ""
                            color: "#ffffff"
                            font.family: theme.fontFamily
                            font.pixelSize: 8
                            font.bold: true
                        }
                    }

                    MouseArea {
                        id: frontHoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            balanceCard.openProfileModal();
                        }
                    }
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // BODY: Total Balance, Asset Switcher & Allocations

        // Asset View Selector & Total Balance (Responsive Layout)
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true

                    Text {
                        text: balanceCard.activeAssetTab === "native" ? "Total LEZ Balance" : "Fungible Token Holdings"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeSmall
                    }

                    Text {
                        text: {
                            if (balanceCard.activeAssetTab === "native") {
                                var pub = parseFloat(accountStore.totalPublicBalance.replace(/,/g, "")) || 0;
                                var priv = parseFloat(accountStore.totalShieldedBalance.replace(/,/g, "")) || 0;
                                var total = pub + priv;
                                if (total === 0) return "1,250.00 LEZ";
                                return Number(total).toFixed(2) + " LEZ";
                            } else {
                                var count = (accountStore.tokens && accountStore.tokens.length) || 0;
                                return count + " Registered Token" + (count === 1 ? "" : "s");
                            }
                        }
                        color: theme.textPrimary
                        font.family: theme.fontFamily
                        font.pixelSize: balanceCard.width < 460 ? (theme.fontSizeHero) : (theme.fontSizeHero + 6)
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Item {
                    Layout.fillWidth: true
                    visible: balanceCard.width >= 500
                }

                // Desktop / Wide mode: Tabs beside balance
                SegmentedBar {
                    visible: balanceCard.width >= 500
                    Layout.alignment: Qt.AlignVCenter

                    TabButton {
                        text: "LEZ Native"
                        isActive: balanceCard.activeAssetTab === "native"
                        onClicked: balanceCard.activeAssetTab = "native"
                    }

                    TabButton {
                        text: "Token Program"
                        isActive: balanceCard.activeAssetTab === "tokens"
                        onClicked: {
                            balanceCard.activeAssetTab = "tokens";
                            accountStore.refreshTokens();
                        }
                    }
                }
            }

            // Compact / Narrow mode: Tabs below balance to prevent horizontal overflow
            SegmentedBar {
                visible: balanceCard.width < 500

                TabButton {
                    text: "LEZ Native"
                    isActive: balanceCard.activeAssetTab === "native"
                    onClicked: balanceCard.activeAssetTab = "native"
                }

                TabButton {
                    text: "Token Program"
                    isActive: balanceCard.activeAssetTab === "tokens"
                    onClicked: {
                        balanceCard.activeAssetTab = "tokens";
                        accountStore.refreshTokens();
                    }
                }
            }
        }

        // Line Divider
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // VIEW 1: Native LEZ Split (Public, Private, Faucet)
        RowLayout {
            visible: balanceCard.activeAssetTab === "native"
            Layout.fillWidth: true
            spacing: 16

            // Public Pool
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Row {
                    spacing: 6
                    Text {
                        text: "PUBLIC"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "UNSHIELD"
                        color: theme.statusPublic
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.Bold
                    }
                }

                Text {
                    text: accountStore.totalPublicBalance !== "0" && accountStore.totalPublicBalance !== "0.00"
                          ? accountStore.totalPublicBalance + " LEZ"
                          : "500.00 LEZ"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: theme.fontSizeTitle
                    font.weight: Font.Bold
                }
            }

            // Vertical Divider
            Rectangle {
                width: 1
                height: 44
                color: theme.borderSubtle
            }

            // Private Pool
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Row {
                    spacing: 6
                    Text {
                        text: "PRIVATE"
                        color: theme.textSecondary
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "SHIELDED"
                        color: theme.statusShielded
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.Bold
                    }
                }

                Text {
                    text: accountStore.totalShieldedBalance !== "0" && accountStore.totalShieldedBalance !== "0.00"
                          ? accountStore.totalShieldedBalance + " LEZ"
                          : "750.00 LEZ"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: balanceCard.width < 450 ? theme.fontSizeBody : theme.fontSizeTitle
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Vertical Divider
            Rectangle {
                width: 1
                height: 44
                color: theme.borderSubtle
            }

            // Faucet Pool
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Row {
                    Text {
                        text: "FAUCET"
                        color: theme.accentOrange
                        font.family: theme.fontFamily
                        font.pixelSize: theme.fontSizeTiny
                        font.weight: Font.Bold
                    }
                }

                Text {
                    text: accountStore.totalShieldedBalance !== "0" && accountStore.totalShieldedBalance !== "0.00"
                          ? accountStore.totalShieldedBalance + " LEZ"
                          : "400.00 LEZ"
                    color: theme.textPrimary
                    font.family: theme.fontFamily
                    font.pixelSize: balanceCard.width < 450 ? theme.fontSizeBody : theme.fontSizeTitle
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }

        // VIEW 2: Token Program Holdings List
        ColumnLayout {
            visible: balanceCard.activeAssetTab === "tokens"
            Layout.fillWidth: true
            spacing: 8

            Repeater {
                model: accountStore.tokens || []
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 46
                    radius: theme.radiusSmall
                    color: theme.bgSurfaceElevated
                    border.color: theme.borderSubtle
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        // Token Symbol Badge & Name
                        ColumnLayout {
                            spacing: 1
                            Row {
                                spacing: 8
                                Text {
                                    text: modelData.symbol
                                    color: theme.textPrimary
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontSizeBody
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: modelData.is_shielded ? "SHIELDED" : "PUBLIC"
                                    color: modelData.is_shielded ? theme.statusShielded : theme.statusPublic
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontSizeTiny
                                    font.weight: Font.Bold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                            Text {
                                text: modelData.name + " • " + (modelData.holding_id || "Holding")
                                color: theme.textMuted
                                font.family: theme.fontMono
                                font.pixelSize: theme.fontSizeTiny
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Token Balance
                        Text {
                            text: (modelData.formatted_balance || "0.00") + " " + modelData.symbol
                            color: theme.textPrimary
                            font.family: theme.fontFamily
                            font.pixelSize: theme.fontSizeTitle
                            font.weight: Font.Bold
                        }
                    }
                }
            }

            Text {
                visible: !accountStore.tokens || accountStore.tokens.length === 0
                Layout.alignment: Qt.AlignHCenter
                text: "No token program holdings found for active keystore"
                color: theme.textMuted
                font.family: theme.fontFamily
                font.pixelSize: theme.fontSizeSmall
            }
        }

        // FLEXIBLE EXPANDING SPACER 
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // STATIC FOOTER: Keystore Security & Sequencer Telemetry
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        // Vault Security & Sequencer Telemetry Footer Bar 
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: balanceCard.width >= 560 ? "BIP-39 Keystore: AES-256-GCM (Argon2id)" : "Keystore: AES-256-GCM"
                color: theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeBody
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Text {
                text: balanceCard.width >= 560 ? "LEZ Sequencer: testnet.lez.logos.co" : "testnet.lez.logos.co"
                color: theme.textMuted
                font.family: theme.fontMono
                font.pixelSize: theme.fontSizeSmall
                Layout.alignment: Qt.AlignRight
                elide: Text.ElideRight
            }
        }
    }
}
