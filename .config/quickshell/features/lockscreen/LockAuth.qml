import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import qs.config
import qs.components.base

ColumnLayout {
    id: root

    spacing: 16

    signal authSuccess

    property string statusMessage: ""
    property string statusType: ""
    property bool _isProcessing: false
    property string _pendingPassword: ""

    function focusInput() {
        passwordInput.forceActiveFocus()
    }

    Component.onCompleted: {
        Qt.callLater(() => passwordInput.forceActiveFocus())
    }

    function submitPassword() {
        if (passwordInput.text.length > 0 && !root._isProcessing) {
            root._pendingPassword = passwordInput.text
            passwordInput.text = ""
            pamContext.start()
            root._isProcessing = true
        }
    }

    Rectangle {
        id: authCard
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: Settings.lockscreenCardWidth
        Layout.preferredHeight: Settings.lockscreenInputHeight + 60
        color: Qt.rgba(Theme.surfaceBase.r, Theme.surfaceBase.g, Theme.surfaceBase.b, 0.85)
        radius: Settings.screenCornerRadius
        border.color: Theme.cardBorder
        border.width: 1

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 16
            width: parent.width - Settings.lockscreenCardPadding * 2

            Rectangle {
                id: passwordField
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: parent.width
                Layout.preferredHeight: Settings.lockscreenInputHeight
                color: Qt.rgba(Theme.surfaceHighest.r, Theme.surfaceHighest.g, Theme.surfaceHighest.b, 0.5)
                radius: Settings.lockscreenInputRadius
                border.color: passwordInput.activeFocus ? Theme.primary : Theme.borderDefault
                border.width: passwordInput.activeFocus ? 2 : 1

                Behavior on border.color {
                    ColorAnimation {
                        duration: Settings.animationDurationShort
                        easing.type: Easing.OutCubic
                    }
                }

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 50
                    verticalAlignment: Text.AlignVCenter
                    echoMode: TextInput.Password
                    color: "#ffffff"
                    font.pixelSize: Settings.fontSizeMedium
                    font.family: Settings.fontFamilyDefault
                    selectByMouse: false
                    activeFocusOnTab: true
                    activeFocusOnPress: true

                    onAccepted: {
                        root.submitPassword()
                    }

                    Keys.onPressed: (event) => {
                        if (event.key === Qt.Key_Escape) {
                            passwordInput.text = ""
                            event.accepted = true
                        }
                    }
                }

                Text {
                    id: placeholderText
                    anchors.centerIn: parent
                    text: "Enter password"
                    color: Qt.rgba(1.0, 1.0, 1.0, 0.5)
                    font.pixelSize: Settings.fontSizeMedium
                    visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
                }

                IconButton {
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "→"
                    iconSize: 16
                    buttonSize: 32
                    onClicked: {
                        root.submitPassword()
                    }
                }
            }

            Text {
                id: statusText
                Layout.alignment: Qt.AlignHCenter
                text: root.statusMessage
                color: {
                    if (root.statusType === "error") return Theme.error
                    if (root.statusType === "success") return Theme.primary
                    return "#ffffff"
                }
                font.pixelSize: Settings.fontSizeSmall
                font.weight: Font.Normal
                horizontalAlignment: Text.AlignHCenter
                visible: root.statusMessage.length > 0
                opacity: visible ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Settings.animationDurationShort
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    PamContext {
        id: pamContext
        config: "quickshell"
        configDirectory: Quickshell.shellDir + "/features/lockscreen/pam.d"

        onActiveChanged: {
            if (active && passwordInput.text.length > 0) {
                pamContext.respond(passwordInput.text)
                passwordInput.text = ""
            }
        }

        onResponseRequiredChanged: {
            if (responseRequired && root._pendingPassword.length > 0) {
                pamContext.respond(root._pendingPassword)
                root._pendingPassword = ""
            }
        }

        onCompleted: (result) => {
            root._isProcessing = false
            if (result === PamResult.Success) {
                root.statusMessage = "Unlocking..."
                root.statusType = "success"
                root.authSuccess()
            } else if (result === PamResult.Failed) {
                root.statusMessage = "Incorrect password"
                root.statusType = "error"
                Qt.callLater(() => passwordInput.forceActiveFocus())
                shakeAnimation.start()
            } else if (result === PamResult.Error) {
                root.statusMessage = "Authentication error"
                root.statusType = "error"
                Qt.callLater(() => passwordInput.forceActiveFocus())
            } else if (result === PamResult.MaxTries) {
                root.statusMessage = "Too many attempts"
                root.statusType = "error"
            }
        }

        onMessageChanged: {
            if (message.length > 0) {
                root.statusMessage = message
                root.statusType = "info"
            }
        }
    }

    SequentialAnimation {
        id: shakeAnimation
        ParallelAnimation {
            NumberAnimation {
                target: authCard
                property: "x"
                to: -8
                duration: 80
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: authCard
                property: "opacity"
                to: 0.8
                duration: 80
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: authCard
                property: "x"
                to: 8
                duration: 80
                easing.type: Easing.OutQuad
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: authCard
                property: "x"
                to: -4
                duration: 80
                easing.type: Easing.OutQuad
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: authCard
                property: "x"
                to: 4
                duration: 80
                easing.type: Easing.OutQuad
            }
        }
        ParallelAnimation {
            NumberAnimation {
                target: authCard
                property: "x"
                to: 0
                duration: 80
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                target: authCard
                property: "opacity"
                to: 1
                duration: 80
            }
        }
    }

    Timer {
        id: statusClearTimer
        interval: 3000
        onTriggered: {
            if (root.statusType !== "error") {
                root.statusMessage = ""
                root.statusType = ""
            }
        }
    }

    onStatusMessageChanged: {
        if (root.statusMessage.length > 0) {
            statusClearTimer.restart()
        }
    }
}
