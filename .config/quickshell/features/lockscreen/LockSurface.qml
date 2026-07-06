pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pam
import qs.config

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock

    property bool _isUnlocking: false
    property bool _showContent: false
    property real _toolbarScale: 0.9
    property real _toolbarOpacity: 0
    property string statusMessage: ""
    property string statusType: ""
    property bool _isProcessing: false
    property string _pendingPassword: ""

    color: Qt.rgba(0, 0, 0, 1)

    Component.onCompleted: {
        console.log("LockSurface created")
        lockAnimTimer.start()
    }

    Timer {
        id: lockAnimTimer
        interval: 150
        onTriggered: {
            root._showContent = true
            root._toolbarScale = 1
            root._toolbarOpacity = 1
            Qt.callLater(() => passwordInput.forceActiveFocus())
        }
    }

    Connections {
        target: root.lock

        function onUnlockRequested() {
            root._isUnlocking = true
            root._toolbarScale = 0.9
            root._toolbarOpacity = 0
            unlockCompleteTimer.restart()
        }
    }

    Timer {
        id: unlockCompleteTimer
        interval: 400
        onTriggered: {
            root.lock.locked = false
            root._showContent = false
        }
    }

    // Wallpaper background
    Image {
        id: wallpaper
        anchors.fill: parent
        source: Settings.backgroundImagePath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        opacity: root._isUnlocking ? 0 : (root._showContent ? 1 : 0)

        Behavior on opacity {
            NumberAnimation {
                duration: Settings.animationDurationMedium
                easing.type: Easing.OutCubic
            }
        }
    }

    // Dark overlay
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.35)
        opacity: root._isUnlocking ? 0 : (root._showContent ? 1 : 0)

        Behavior on opacity {
            NumberAnimation {
                duration: Settings.animationDurationMedium
                easing.type: Easing.OutCubic
            }
        }
    }

    // Full-screen mouse area to focus input
    MouseArea {
        anchors.fill: parent
        onClicked: passwordInput.forceActiveFocus()
        onPositionChanged: passwordInput.forceActiveFocus()
    }

    // Key capture
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            passwordInput.text = ""
            event.accepted = true
        }
        passwordInput.forceActiveFocus()
    }

    // Clock centered on screen
    ColumnLayout {
        anchors.centerIn: parent
        spacing: 8
        opacity: (root._showContent && !root._isUnlocking) ? 1 : 0
        y: (root._showContent && !root._isUnlocking) ? 0 : 20

        Behavior on opacity {
            NumberAnimation {
                duration: Settings.animationDurationLong
                easing.type: Easing.OutCubic
            }
        }

        Behavior on y {
            NumberAnimation {
                duration: Settings.animationDurationLong
                easing.type: Easing.OutCubic
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(new Date(), Settings.lockscreenTimeFormat)
            color: "#ffffff"
            font.pixelSize: Settings.lockscreenClockSize
            font.weight: Font.Light
            horizontalAlignment: Text.AlignHCenter

            Timer {
                interval: 1000
                repeat: true
                running: true
                onTriggered: parent.text = Qt.formatTime(new Date(), Settings.lockscreenTimeFormat)
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatDate(new Date(), Settings.lockscreenDateFormat)
            color: Qt.rgba(1.0, 1.0, 1.0, 0.65)
            font.pixelSize: Settings.lockscreenDateSize
            font.weight: Font.Normal
            horizontalAlignment: Text.AlignHCenter
        }
    }

    // Bottom toolbar (end-4 style)
    RowLayout {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20
        }
        spacing: 10
        scale: root._toolbarScale
        opacity: root._toolbarOpacity

        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
                easing.bezierCurve: [0.05, 0.7, 0.1, 1]
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }

        // Username pill
        Rectangle {
            color: Qt.rgba(Theme.surfaceBase.r, Theme.surfaceBase.g, Theme.surfaceBase.b, 0.5)
            radius: height / 2
            height: 40
            implicitWidth: usernameText.implicitWidth + 40

            Row {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "\ue7fd"
                    font.family: Settings.fontFamilyIcons
                    font.pixelSize: 16
                }

                Text {
                    id: usernameText
                    text: Settings.username
                    color: Theme.textSecondary
                    font.pixelSize: Settings.fontSizeMedium
                }
            }
        }

        // Password input pill
        Rectangle {
            id: passwordCard
            color: Qt.rgba(Theme.surfaceBase.r, Theme.surfaceBase.g, Theme.surfaceBase.b, 0.8)
            radius: height / 2
            height: 48
            implicitWidth: 280
            border.color: passwordInput.activeFocus ? Theme.primary : "transparent"
            border.width: passwordInput.activeFocus ? 2 : 0

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
                activeFocusOnPress: true

                onAccepted: {
                    if (text.length > 0 && !root._isProcessing) {
                        root._pendingPassword = text
                        text = ""
                        pamContext.start()
                        root._isProcessing = true
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                text: root.statusMessage || "Enter password"
                color: {
                    if (root.statusType === "error") return Theme.error
                    if (root.statusType === "success") return Theme.primary
                    return Qt.rgba(1.0, 1.0, 1.0, 0.4)
                }
                font.pixelSize: Settings.fontSizeMedium
                visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
            }

            // Submit button
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                radius: 16
                color: Theme.primary
                visible: passwordInput.text.length > 0

                Text {
                    anchors.centerIn: parent
                    text: "\ue5c8"
                    color: "#ffffff"
                    font.family: Settings.fontFamilyIcons
                    font.pixelSize: 16
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (passwordInput.text.length > 0 && !root._isProcessing) {
                            root._pendingPassword = passwordInput.text
                            passwordInput.text = ""
                            pamContext.start()
                            root._isProcessing = true
                        }
                    }
                }
            }
        }

        // Power button pill
        Rectangle {
            color: Qt.rgba(Theme.surfaceBase.r, Theme.surfaceBase.g, Theme.surfaceBase.b, 0.5)
            radius: height / 2
            height: 40
            width: 40

            Text {
                anchors.centerIn: parent
                text: "\ue8ac"
                color: Theme.textSecondary
                font.family: Settings.fontFamilyIcons
                font.pixelSize: 18
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    Qt.callLater(() => {
                        var proc = new Process()
                        proc.command = ["systemctl", "poweroff"]
                        proc.running = true
                    })
                }
            }
        }
    }

    PamContext {
        id: pamContext
        config: "quickshell"
        configDirectory: Quickshell.shellDir + "/features/lockscreen/pam.d"

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
                root.lock.unlockRequested()
            } else if (result === PamResult.Failed) {
                root.statusMessage = "Incorrect password"
                root.statusType = "error"
                Qt.callLater(() => passwordInput.forceActiveFocus())
                shakeAnim.start()
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

    // Shake animation for wrong password
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: passwordCard; property: "x"; to: -8; duration: 80; easing.type: Easing.OutQuad }
        NumberAnimation { target: passwordCard; property: "x"; to: 8; duration: 80; easing.type: Easing.OutQuad }
        NumberAnimation { target: passwordCard; property: "x"; to: -4; duration: 80; easing.type: Easing.OutQuad }
        NumberAnimation { target: passwordCard; property: "x"; to: 4; duration: 80; easing.type: Easing.OutQuad }
        NumberAnimation { target: passwordCard; property: "x"; to: 0; duration: 80; easing.type: Easing.OutQuad }
    }
}
