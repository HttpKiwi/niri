pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pam
import qs.config
import qs.core

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock

    readonly property real overlayStrength: 0.38

    property real _blurAmount: 0
    property real _overlayOpacity: 0
    property real _clockOpacity: 0
    property real _clockOffset: 28
    property real _toolbarScale: 0.92
    property real _toolbarOpacity: 0
    property string statusMessage: ""
    property string statusType: ""
    property bool _isProcessing: false
    property string _pendingPassword: ""

    color: "transparent"

    Component.onCompleted: {
        lockEnterAnim.start()
    }

    Connections {
        target: root.lock

        function onUnlockRequested() {
            if (!unlockAnim.running)
                unlockAnim.start()
        }
    }

    SequentialAnimation {
        id: lockEnterAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "_blurAmount"
                to: Settings.lockscreenBackdropBlur
                duration: Settings.animationDurationLong
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "_overlayOpacity"
                to: 1
                duration: Settings.animationDurationLong
                easing.type: Easing.OutCubic
            }
        }

        PauseAnimation { duration: 60 }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "_clockOpacity"
                to: 1
                duration: Settings.animationDurationLong
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "_clockOffset"
                to: 0
                duration: Settings.animationDurationLong
                easing.type: Easing.OutCubic
            }
        }

        PauseAnimation { duration: 80 }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "_toolbarOpacity"
                to: 1
                duration: Settings.animationDurationMedium
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: root
                property: "_toolbarScale"
                to: 1
                duration: 320
                easing.type: Easing.OutCubic
                easing.bezierCurve: [0.05, 0.7, 0.1, 1]
            }
        }

        ScriptAction {
            script: Qt.callLater(() => passwordInput.forceActiveFocus())
        }
    }

    SequentialAnimation {
        id: unlockAnim

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "_toolbarOpacity"
                to: 0
                duration: Settings.animationDurationShort
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: root
                property: "_toolbarScale"
                to: 0.92
                duration: Settings.animationDurationMedium
                easing.type: Easing.InCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "_clockOpacity"
                to: 0
                duration: Settings.animationDurationMedium
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: root
                property: "_clockOffset"
                to: 18
                duration: Settings.animationDurationMedium
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: root
                property: "_overlayOpacity"
                to: 0
                duration: Settings.animationDurationMedium
                easing.type: Easing.InCubic
            }
            NumberAnimation {
                target: root
                property: "_blurAmount"
                to: 0
                duration: Settings.animationDurationLong
                easing.type: Easing.InCubic
            }
        }

        ScriptAction {
            script: root.lock.locked = false
        }
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: Settings.backgroundImagePath
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true

        layer.enabled: root._blurAmount > 0.5
        layer.effect: MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blur: 1
            blurMax: root._blurAmount
            blurMultiplier: 1
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Settings.backgroundColor
        visible: !Settings.backgroundImagePath
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, overlayStrength)
        opacity: root._overlayOpacity
    }

    MouseArea {
        anchors.fill: parent
        onClicked: passwordInput.forceActiveFocus()
        onPositionChanged: passwordInput.forceActiveFocus()
    }

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            passwordInput.text = ""
            event.accepted = true
        }
        passwordInput.forceActiveFocus()
    }

    ColumnLayout {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -root._clockOffset
        spacing: 8
        opacity: root._clockOpacity

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Qt.formatTime(new Date(), Settings.lockscreenTimeFormat)
            color: "#ffffff"
            font.pixelSize: Settings.lockscreenClockSize
            font.weight: Font.Light
            font.family: Settings.fontFamilyDefault
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
            font.family: Settings.fontFamilyDefault
            horizontalAlignment: Text.AlignHCenter
        }
    }

    RowLayout {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20
        }
        spacing: 10
        scale: root._toolbarScale
        opacity: root._toolbarOpacity
        transformOrigin: Item.Bottom

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
                    font.family: Settings.fontFamilyDefault
                }
            }
        }

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
                font.family: Settings.fontFamilyDefault
                visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
            }

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

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: passwordCard; property: "x"; to: -8; duration: 80; easing.type: Easing.OutQuad }
        NumberAnimation { target: passwordCard; property: "x"; to: 8; duration: 80; easing.type: Easing.OutQuad }
        NumberAnimation { target: passwordCard; property: "x"; to: -4; duration: 80; easing.type: Easing.OutQuad }
        NumberAnimation { target: passwordCard; property: "x"; to: 4; duration: 80; easing.type: Easing.OutQuad }
        NumberAnimation { target: passwordCard; property: "x"; to: 0; duration: 80; easing.type: Easing.OutQuad }
    }
}
