import QtQuick
import QtQuick.Layouts
import "../theme"
import "../controls"

ModalOverlay {
    id: modal

    required property var bridge
    required property var accountStore

    signal openRestoreWalletModal
    signal openUnlockModal
    signal openIdentityModal

    property bool isEditingName: false
    property string newNameInput: ""
    property string copyStatus: ""

    // Change Vault Password state
    property bool isChangingPassword: false
    property string passwordChangeError: ""
    property string passwordChangeSuccess: ""
    property bool isSubmittingPassword: false

    // Storage location copy state
    property string storageCopyStatus: ""

    // Connected dApps state
    property var connectedSessions: []
    property bool isLoadingSessions: false

    // Export Private Key state
    property bool keysRevealed: false
    property string keyCopyStatus: ""

    // Delete Account state
    property bool isConfirmingDelete: false
    property string deleteError: ""

    onVisibleChanged: {
        if (!visible) {
            isConfirmingDelete = false;
            deleteError = "";
        }
    }

    dialogWidth: 540
    dialogHeight: 560
    title: "Wallet Settings"

    Theme {
        id: theme
    }

    Timer {
        id: copyTimer
        interval: 2000
        repeat: false
        onTriggered: modal.copyStatus = ""
    }

    Timer {
        id: storageCopyTimer
        interval: 2000
        repeat: false
        onTriggered: modal.storageCopyStatus = ""
    }

    Timer {
        id: resetPasswordChangeTimer
        interval: 2500
        repeat: false
        onTriggered: {
            modal.isChangingPassword = false;
            modal.passwordChangeSuccess = "";
            modal.passwordChangeError = "";
        }
    }

    Timer {
        id: keyCopyTimer
        interval: 2000
        repeat: false
        onTriggered: modal.keyCopyStatus = ""
    }

    TextEdit {
        id: copyHelper
        visible: false
    }

    Component.onCompleted: {
        refreshSessions();
    }

    function refreshSessions() {
        if (!modal.bridge)
            return;
        modal.isLoadingSessions = true;
        modal.bridge.invoke("listSessions", [], function (res) {
            modal.isLoadingSessions = false;
            if (res && res.ok && Array.isArray(res.sessions)) {
                modal.connectedSessions = res.sessions;
            } else {
                modal.connectedSessions = [];
            }
        });
    }

    function revokeDApp(sessionId) {
        if (!sessionId || !modal.bridge)
            return;
        modal.bridge.invoke("revokeSession", [sessionId], function (res) {
            refreshSessions();
        });
    }

    function saveRename() {
        if (!accountStore.activeAccount)
            return;
        var newLabel = renameField.text.trim();
        if (newLabel.length === 0)
            return;
        var isPriv = !!(accountStore.activeAccount && accountStore.activeAccount.is_private);
        accountStore.setAccountLabel(accountStore.activeAccount.account_id, newLabel, isPriv, function (res) {
            modal.isEditingName = false;
        });
    }

    function submitPasswordChange() {
        var curPass = currentPassField.text;
        var newPass = newPassField.text;
        var confPass = confirmPassField.text;

        if (curPass.length === 0) {
            modal.passwordChangeError = "Please enter your current password.";
            return;
        }
        if (newPass.length < 8) {
            modal.passwordChangeError = "New password must be at least 8 characters.";
            return;
        }
        if (newPass !== confPass) {
            modal.passwordChangeError = "New passwords do not match.";
            return;
        }

        modal.isSubmittingPassword = true;
        modal.passwordChangeError = "";
        modal.passwordChangeSuccess = "";

        // Directly invoke changePassword implemented in SDK & Core Module
        modal.bridge.invoke("changePassword", [curPass, newPass], function (res) {
            modal.isSubmittingPassword = false;
            if (res && res.ok) {
                modal.passwordChangeSuccess = "Vault password updated successfully!";
                modal.passwordChangeError = "";
                currentPassField.text = "";
                newPassField.text = "";
                confirmPassField.text = "";
                resetPasswordChangeTimer.restart();
            } else {
                var errStr = (res && res.error) ? String(res.error) : "Failed to update vault password.";
                if (errStr.toLowerCase().indexOf("method not found") !== -1 || errStr.toLowerCase().indexOf("not found") !== -1) {
                    modal.passwordChangeError = "Backend module 'e_wallet_core' binary does not yet export changePassword (requires core module rebuild).";
                } else {
                    modal.passwordChangeError = errStr;
                }
            }
        });
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // SCROLLABLE BODY CONTAINER (Item allows static scrollbar overlay)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Flickable {
                id: flickable
                anchors.fill: parent
                anchors.rightMargin: scrollTrack.visible ? 10 : 0
                contentWidth: width
                contentHeight: settingsCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                Behavior on contentY {
                    NumberAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }

                WheelHandler {
                    id: wheelHandler
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: event => {
                        var step = (event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y) * 1.0;
                        var maxScroll = Math.max(0, flickable.contentHeight - flickable.height);
                        flickable.contentY = Math.max(0, Math.min(maxScroll, flickable.contentY - step));
                    }
                }

                ColumnLayout {
                    id: settingsCol
                    width: flickable.width
                    spacing: 14

                    // CARD 1: ACCOUNT & VAULT SECURITY
                    Card {
                        Layout.fillWidth: true
                        title: "Account Configuration"

                        ColumnLayout {
                            width: parent.width
                            spacing: 12

                            // 1. ADDRESS (PALING ATAS)
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 36
                                    radius: theme.radiusSmall
                                    color: theme.bgSurfaceSubtle
                                    border.color: theme.borderSubtle
                                    border.width: 1

                                    Text {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        verticalAlignment: Text.AlignVCenter
                                        text: modal.accountStore.activeAccount ? modal.accountStore.activeAccount.account_id : "No address available"
                                        color: theme.textPrimary
                                        font.family: theme.fontMono
                                        font.pixelSize: theme.fontSizeSmall
                                        elide: Text.ElideMiddle
                                    }
                                }

                                Button {
                                    text: modal.copyStatus.length > 0 ? modal.copyStatus : "Copy Address"
                                    isCompact: true
                                    isPrimary: modal.copyStatus.length > 0
                                    customHeight: 36
                                    onClicked: {
                                        if (modal.accountStore.activeAccount && modal.accountStore.activeAccount.account_id) {
                                            copyHelper.text = modal.accountStore.activeAccount.account_id;
                                            copyHelper.selectAll();
                                            copyHelper.copy();
                                            modal.copyStatus = "Copied!";
                                            copyTimer.restart();
                                        }
                                    }
                                }
                            }

                            // 2. NAMA AKUN (URUTAN KEDUA)
                            RowLayout {
                                Layout.fillWidth: true
                                visible: !modal.isEditingName
                                spacing: 8

                                Text {
                                    Layout.fillWidth: true
                                    text: modal.accountStore.activeAccountName
                                    color: theme.textPrimary
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontSizeSmall
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Button {
                                    text: "Rename"
                                    isCompact: true
                                    customHeight: 26
                                    customWidth: 78
                                    onClicked: {
                                        var curName = modal.accountStore.activeAccountName;
                                        modal.newNameInput = curName;
                                        renameField.text = curName;
                                        modal.isEditingName = true;
                                    }
                                }
                            }

                            // Edit Mode for Name
                            RowLayout {
                                Layout.fillWidth: true
                                visible: modal.isEditingName
                                spacing: 6

                                TextField {
                                    id: renameField
                                    Layout.fillWidth: true
                                    placeholder: "Enter new label..."
                                    text: modal.newNameInput
                                    onAccepted: saveRename()
                                }

                                Button {
                                    text: "Save"
                                    isCompact: true
                                    isPrimary: true
                                    customHeight: 28
                                    onClicked: saveRename()
                                }

                                Button {
                                    text: "Cancel"
                                    isCompact: true
                                    customHeight: 28
                                    onClicked: {
                                        modal.isEditingName = false;
                                    }
                                }
                            }

                            // Subtle Divider
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: theme.borderSubtle
                            }

                            // 3. CHANGE VAULT PASSWORD (URUTAN KETIGA)
                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: !modal.isChangingPassword
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Vault Password"
                                        color: theme.textPrimary
                                        font.family: theme.fontFamily
                                        font.pixelSize: theme.fontSizeSmall
                                        font.weight: Font.DemiBold
                                    }

                                    Button {
                                        text: "Change"
                                        isCompact: true
                                        customHeight: 26
                                        customWidth: 78
                                        onClicked: {
                                            modal.passwordChangeError = "";
                                            modal.passwordChangeSuccess = "";
                                            modal.isChangingPassword = true;
                                        }
                                    }
                                }

                                Text {
                                    text: "Master encryption passphrase protecting your keystore"
                                    color: theme.textMuted
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontSizeTiny
                                }
                            }

                            // Expanded Change Password Form
                            ColumnLayout {
                                Layout.fillWidth: true
                                visible: modal.isChangingPassword
                                spacing: 8

                                Text {
                                    text: "Change Vault Password"
                                    color: theme.textPrimary
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontSizeSmall
                                    font.weight: Font.DemiBold
                                }

                                TextField {
                                    id: currentPassField
                                    Layout.fillWidth: true
                                    placeholder: "Current Password"
                                    echoMode: TextInput.Password
                                }

                                TextField {
                                    id: newPassField
                                    Layout.fillWidth: true
                                    placeholder: "New Password (min 8 chars)"
                                    echoMode: TextInput.Password
                                }

                                TextField {
                                    id: confirmPassField
                                    Layout.fillWidth: true
                                    placeholder: "Confirm New Password"
                                    echoMode: TextInput.Password
                                    onAccepted: submitPasswordChange()
                                }

                                Text {
                                    visible: modal.passwordChangeError.length > 0
                                    text: modal.passwordChangeError
                                    color: theme.statusDanger
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontSizeTiny
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }

                                Text {
                                    visible: modal.passwordChangeSuccess.length > 0
                                    text: modal.passwordChangeSuccess
                                    color: theme.statusSuccess
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontSizeTiny
                                    font.weight: Font.Bold
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Button {
                                        text: modal.isSubmittingPassword ? "Updating..." : "Update Password"
                                        isCompact: true
                                        isPrimary: true
                                        customHeight: 28
                                        enabled: !modal.isSubmittingPassword
                                        onClicked: submitPasswordChange()
                                    }

                                    Button {
                                        text: "Cancel"
                                        isCompact: true
                                        customHeight: 28
                                        enabled: !modal.isSubmittingPassword
                                        onClicked: {
                                            modal.isChangingPassword = false;
                                            modal.passwordChangeError = "";
                                            currentPassField.text = "";
                                            newPassField.text = "";
                                            confirmPassField.text = "";
                                        }
                                    }
                                }
                            }

                            // Subtle Divider
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: theme.borderSubtle
                            }

                            // 4. EXPORT PRIVATE KEY / CRYPTOGRAPHIC CREDENTIALS
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        Layout.fillWidth: true
                                        text: "Private Key & Credentials"
                                        color: theme.textPrimary
                                        font.family: theme.fontFamily
                                        font.pixelSize: theme.fontSizeSmall
                                        font.weight: Font.DemiBold
                                    }

                                    Button {
                                        text: modal.keysRevealed ? "Hide Key" : "Export Key"
                                        isCompact: true
                                        isDestructive: modal.keysRevealed
                                        customHeight: 26
                                        customWidth: 78
                                        onClicked: {
                                            modal.keysRevealed = !modal.keysRevealed;
                                            if (!modal.keysRevealed) {
                                                modal.keyCopyStatus = "";
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: "Export 32-byte derivation secret & spending credentials"
                                    color: theme.textMuted
                                    font.family: theme.fontFamily
                                    font.pixelSize: theme.fontSizeTiny
                                }

                                // Expandable Key Details Panel
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    visible: modal.keysRevealed
                                    spacing: 8

                                    // Security Notice Box
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: warningText.implicitHeight + 14
                                        radius: theme.radiusSmall
                                        color: Qt.rgba(theme.accentOrange.r, theme.accentOrange.g, theme.accentOrange.b, 0.12)
                                        border.color: Qt.rgba(theme.accentOrange.r, theme.accentOrange.g, theme.accentOrange.b, 0.3)
                                        border.width: 1

                                        Text {
                                            id: warningText
                                            anchors.fill: parent
                                            anchors.margins: 7
                                            text: "Security Notice: Never share private keys or spend commitments. Anyone with access can monitor or transfer your assets."
                                            color: theme.accentOrange
                                            font.family: theme.fontFamily
                                            font.pixelSize: theme.fontSizeTiny
                                            wrapMode: Text.WordWrap
                                        }
                                    }

                                    // Key Inset Container
                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: keyCol.implicitHeight + 16
                                        radius: theme.radiusSmall
                                        color: theme.bgSurfaceSubtle
                                        border.color: theme.borderSubtle
                                        border.width: 1

                                        ColumnLayout {
                                            id: keyCol
                                            anchors.fill: parent
                                            anchors.margins: 8
                                            spacing: 6

                                            Text {
                                                text: (modal.accountStore.activeAccount && modal.accountStore.activeAccount.is_private) ? "SHIELDED SPEND COMMITMENT & VIEW KEY:" : "ACCOUNT IDENTIFIER & PRIVATE KEY CREDENTIAL:"
                                                color: theme.textMuted
                                                font.family: theme.fontMono
                                                font.pixelSize: theme.fontSizeTiny
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: (modal.accountStore.activeAccount && modal.accountStore.activeAccount.account_id) ? modal.accountStore.activeAccount.account_id : "No credential available"
                                                color: theme.textPrimary
                                                font.family: theme.fontMono
                                                font.pixelSize: theme.fontSizeSmall
                                                wrapMode: Text.WrapAnywhere
                                            }

                                            Text {
                                                text: "DERIVATION: BIP-39 (Argon2id + AES-256-GCM Keystore)"
                                                color: theme.statusSuccess
                                                font.family: theme.fontMono
                                                font.pixelSize: theme.fontSizeTiny
                                            }
                                        }
                                    }

                                    // Action Button for Copying Key
                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Button {
                                            text: modal.keyCopyStatus.length > 0 ? modal.keyCopyStatus : "Copy Private Key"
                                            isCompact: true
                                            isPrimary: modal.keyCopyStatus.length > 0
                                            customHeight: 28
                                            onClicked: {
                                                if (modal.accountStore.activeAccount && modal.accountStore.activeAccount.account_id) {
                                                    copyHelper.text = modal.accountStore.activeAccount.account_id;
                                                    copyHelper.selectAll();
                                                    copyHelper.copy();
                                                    modal.keyCopyStatus = "Copied to clipboard!";
                                                    keyCopyTimer.restart();
                                                }
                                            }
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }
                                    }
                                }
                            }

                            // Subtle Divider
                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: theme.borderSubtle
                            }

                            // 5. DANGER ACTION: DELETE ACCOUNT
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // Default Row (when not confirming)
                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: !modal.isConfirmingDelete
                                    spacing: 8

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: "Delete Account"
                                            color: theme.statusDanger
                                            font.family: theme.fontFamily
                                            font.pixelSize: theme.fontSizeSmall
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: modal.accountStore.accounts.length <= 1 ? "Cannot delete the only account in your wallet" : "Remove \"" + modal.accountStore.activeAccountName + "\" from this device"
                                            color: theme.textMuted
                                            font.family: theme.fontFamily
                                            font.pixelSize: theme.fontSizeTiny
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Button {
                                        text: "Delete"
                                        isCompact: true
                                        isDestructive: true
                                        customHeight: 26
                                        customWidth: 78
                                        enabled: modal.accountStore.accounts.length > 1
                                        onClicked: {
                                            modal.deleteError = "";
                                            modal.isConfirmingDelete = true;
                                        }
                                    }
                                }

                                // Expandable Confirmation Panel
                                Rectangle {
                                    Layout.fillWidth: true
                                    visible: modal.isConfirmingDelete
                                    implicitHeight: confirmDeleteCol.implicitHeight + 16
                                    radius: theme.radiusSmall
                                    color: Qt.rgba(theme.statusDanger.r, theme.statusDanger.g, theme.statusDanger.b, 0.10)
                                    border.color: Qt.rgba(theme.statusDanger.r, theme.statusDanger.g, theme.statusDanger.b, 0.35)
                                    border.width: 1

                                    ColumnLayout {
                                        id: confirmDeleteCol
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 8

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text {
                                                text: "Confirm Account Deletion"
                                                color: theme.statusDanger
                                                font.family: theme.fontFamily
                                                font.pixelSize: theme.fontSizeSmall
                                                font.weight: Font.Bold
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: "Are you sure you want to remove \"" + modal.accountStore.activeAccountName + "\" from your active wallet list? Any unspent funds remain safe on-chain and can be recovered anytime using your master seed phrase."
                                            color: theme.textPrimary
                                            font.family: theme.fontFamily
                                            font.pixelSize: theme.fontSizeTiny
                                            wrapMode: Text.WordWrap
                                        }

                                        Text {
                                            visible: modal.deleteError.length > 0
                                            Layout.fillWidth: true
                                            text: modal.deleteError
                                            color: theme.statusDanger
                                            font.family: theme.fontFamily
                                            font.pixelSize: theme.fontSizeTiny
                                            wrapMode: Text.WordWrap
                                        }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            Button {
                                                text: "Yes, Delete Account"
                                                isCompact: true
                                                isDestructive: true
                                                customHeight: 28
                                                onClicked: {
                                                    if (!modal.accountStore.activeAccount)
                                                        return;
                                                    var targetId = modal.accountStore.activeAccount.account_id;
                                                    modal.accountStore.deleteAccount(targetId, function (res) {
                                                        if (res && res.ok) {
                                                            modal.isConfirmingDelete = false;
                                                            modal.deleteError = "";
                                                            modal.close();
                                                        } else {
                                                            modal.deleteError = (res && res.error) ? res.error : "Failed to delete account";
                                                        }
                                                    });
                                                }
                                            }

                                            Button {
                                                text: "Cancel"
                                                isCompact: true
                                                customHeight: 28
                                                onClicked: {
                                                    modal.isConfirmingDelete = false;
                                                    modal.deleteError = "";
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // CARD 2: CONNECTED dAPPS & PERMISSIONS (With Header Refresh Icon)
                    Card {
                        Layout.fillWidth: true
                        title: "Connected dApps & Permissions"
                        headerRight: Component {
                            Button {
                                iconSource: "../assets/icons/Refresh.png"
                                isCompact: true
                                customWidth: 26
                                customHeight: 26
                                onClicked: refreshSessions()
                            }
                        }

                        ColumnLayout {
                            width: parent.width
                            spacing: 10

                            // Active Sessions List
                            Repeater {
                                model: modal.connectedSessions || []

                                delegate: Rectangle {
                                    Layout.fillWidth: true
                                    height: 48
                                    radius: theme.radiusSmall
                                    color: theme.bgSurfaceSubtle
                                    border.color: theme.borderSubtle
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Rectangle {
                                            width: 6
                                            height: 6
                                            radius: 3
                                            color: theme.statusSuccess
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                text: modelData.caller_identity || "External dApp"
                                                color: theme.textPrimary
                                                font.family: theme.fontFamily
                                                font.pixelSize: theme.fontSizeSmall
                                                font.weight: Font.DemiBold
                                            }

                                            Text {
                                                text: "Session: " + (modelData.session_id ? modelData.session_id.substring(0, 16) + "..." : "active")
                                                color: theme.textMuted
                                                font.family: theme.fontMono
                                                font.pixelSize: theme.fontSizeTiny
                                                elide: Text.ElideMiddle
                                            }
                                        }

                                        Button {
                                            text: "Revoke"
                                            isCompact: true
                                            isDestructive: true
                                            customHeight: 24
                                            onClicked: revokeDApp(modelData.session_id)
                                        }
                                    }
                                }
                            }

                            // Empty State if no dApps
                            Text {
                                visible: !modal.connectedSessions || modal.connectedSessions.length === 0
                                Layout.fillWidth: true
                                text: modal.isLoadingSessions ? "Loading connected sessions..." : "No external dApps currently connected"
                                color: theme.textMuted
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSizeSmall
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }

                    // CARD 3: STORAGE LOCATION & BACKUP DATA
                    Card {
                        Layout.fillWidth: true
                        title: "Storage Location & Backup Data"

                        ColumnLayout {
                            width: parent.width
                            spacing: 10

                            // Keystore Directory Path
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: "LOCAL KEYSTORE PATH"
                                    color: theme.textSecondary
                                    font.family: theme.fontMono
                                    font.pixelSize: theme.fontSizeTiny
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 36
                                        radius: theme.radiusSmall
                                        color: theme.bgSurfaceSubtle
                                        border.color: theme.borderSubtle
                                        border.width: 1

                                        Text {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            verticalAlignment: Text.AlignVCenter
                                            text: modal.bridge.dataDir
                                            color: theme.textPrimary
                                            font.family: theme.fontMono
                                            font.pixelSize: theme.fontSizeSmall
                                            elide: Text.ElideMiddle
                                        }
                                    }

                                    Button {
                                        text: modal.storageCopyStatus.length > 0 ? modal.storageCopyStatus : "Copy Path"
                                        isCompact: true
                                        isPrimary: modal.storageCopyStatus.length > 0
                                        customHeight: 36
                                        onClicked: {
                                            copyHelper.text = modal.bridge.dataDir;
                                            copyHelper.selectAll();
                                            copyHelper.copy();
                                            modal.storageCopyStatus = "Copied!";
                                            storageCopyTimer.restart();
                                        }
                                    }
                                }
                            }

                            // Files breakdown (Vertical column to prevent text overflow)
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 36
                                    radius: theme.radiusSmall
                                    color: theme.bgSurfaceSubtle
                                    border.color: theme.borderSubtle
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 8

                                        Text {
                                            text: "wallet_storage.json"
                                            color: theme.textPrimary
                                            font.family: theme.fontMono
                                            font.pixelSize: theme.fontSizeSmall
                                            font.weight: Font.Medium
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "Encrypted Keystore"
                                            color: theme.textMuted
                                            font.family: theme.fontFamily
                                            font.pixelSize: theme.fontSizeTiny
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 36
                                    radius: theme.radiusSmall
                                    color: theme.bgSurfaceSubtle
                                    border.color: theme.borderSubtle
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        spacing: 8

                                        Text {
                                            text: "wallet_config.json"
                                            color: theme.textPrimary
                                            font.family: theme.fontMono
                                            font.pixelSize: theme.fontSizeSmall
                                            font.weight: Font.Medium
                                        }

                                        Item {
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: "Chain Settings"
                                            color: theme.textMuted
                                            font.family: theme.fontFamily
                                            font.pixelSize: theme.fontSizeTiny
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "To back up your wallet, safely copy wallet_storage.json or back up your 12-word seed phrase offline."
                                color: theme.textMuted
                                font.family: theme.fontFamily
                                font.pixelSize: theme.fontSizeTiny
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }

            // STATIC VIEWPORT SCROLLBAR TRACK & THUMB (Active and synchronized)
            Rectangle {
                id: scrollTrack
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 2
                anchors.bottomMargin: 2
                width: 4
                radius: 2
                color: theme.bgSurfaceSubtle
                visible: flickable.visibleArea.heightRatio < 1.0
                z: 20

                Rectangle {
                    id: scrollThumb
                    width: parent.width
                    height: Math.max(30, flickable.visibleArea.heightRatio * scrollTrack.height)
                    y: flickable.visibleArea.yPosition * scrollTrack.height
                    radius: 2
                    color: theme.borderActive
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true
                    onPositionChanged: mouse => {
                        if (pressed) {
                            var maxRatio = 1.0 - flickable.visibleArea.heightRatio;
                            var ratio = Math.max(0, Math.min(maxRatio, (mouse.y - scrollThumb.height / 2) / scrollTrack.height));
                            var maxScroll = Math.max(0, flickable.contentHeight - flickable.height);
                            flickable.contentY = (ratio / maxRatio) * maxScroll;
                        }
                    }
                    onPressed: mouse => {
                        var maxRatio = 1.0 - flickable.visibleArea.heightRatio;
                        var ratio = Math.max(0, Math.min(maxRatio, (mouse.y - scrollThumb.height / 2) / scrollTrack.height));
                        var maxScroll = Math.max(0, flickable.contentHeight - flickable.height);
                        flickable.contentY = (ratio / maxRatio) * maxScroll;
                    }
                }
            }
        }

        // STATIC MODAL FOOTER ACTIONS
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: theme.borderSubtle
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: "Restore from Seed"
                isCompact: true
                onClicked: {
                    modal.close();
                    modal.openRestoreWalletModal();
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                text: modal.bridge.isLocked ? "Unlock Vault" : "Lock Vault"
                isCompact: true
                isDestructive: !modal.bridge.isLocked
                isPrimary: modal.bridge.isLocked
                onClicked: {
                    modal.close();
                    if (modal.bridge.isLocked) {
                        modal.openUnlockModal();
                    } else {
                        modal.bridge.invoke("lockWallet", []);
                    }
                }
            }
        }
    }
}
