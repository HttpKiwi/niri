pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.config
import qs.overlay
import qs.services

/**
 * Lock - the session lock (ext-session-lock). Locked state lives in the
 * compositor protocol only; there is no IPC unlock, just PAM. The wallpaper
 * goes blurred and dark, the clock grows, a pebble takes the password.
 */
Scope {
    id: root

    readonly property alias locked: lock.locked
    property bool failed: false
    property bool checking: false
    property bool leaving: false
    property string pending: ""

    function lockNow() { if (!lock.locked) { failed = false; leaving = false; lock.locked = true; } }

    PamContext {
        id: pam
        configDirectory: Quickshell.shellPath("pam.d")
        config: "grove"
        onResponseRequiredChanged: if (responseRequired) { respond(root.pending); root.pending = ""; }
        onCompleted: result => {
            root.checking = false;
            if (result === PamResult.Success) root.leaving = true;
            else root.failed = true;
        }
    }
    function submit(pw) {
        if (checking || !pw) return;
        failed = false; checking = true; pending = pw;
        pam.start();
    }

    WlSessionLock {
        id: lock

        WlSessionLockSurface {
            id: surface
            color: "black"

            Item {
                id: scene
                anchors.fill: parent

                // wallpaper, blurred and darkened (only drawn while locked)
                Image {
                    id: wall
                    anchors.fill: parent
                    source: "file://" + Wallpaper.path
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(parent.width / 2, parent.height / 2)   // blurred anyway
                    visible: false
                }
                MultiEffect {
                    anchors.fill: parent
                    source: wall
                    blurEnabled: true
                    blurMax: 48
                    blur: 1.0
                    brightness: -0.25
                    saturation: -0.1
                }
                Rectangle { anchors.fill: parent; color: Qt.rgba(0.04, 0.07, 0.06, 0.55) }

                // everything else fades in together and out before the lock is released
                Item {
                    id: content
                    anchors.fill: parent
                    opacity: 0
                    scale: 0.97
                    Component.onCompleted: { opacity = 1; scale = 1; }
                    Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    states: State { name: "leaving"; when: root.leaving
                        PropertyChanges { content.opacity: 0; content.scale: 1.03 } }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height * 0.28
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatTime(Ambience.now, "HH:mm")
                            font.family: Tune.displayFont
                            font.pixelSize: 132
                            font.weight: Font.DemiBold
                            color: Ambience.phase === "night" ? Tune.ember : Tune.parch
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDate(Ambience.now, "dddd, d MMMM")
                            font.family: Tune.displayFont
                            font.pixelSize: 24
                            color: Tune.parch
                            opacity: 0.75
                        }
                    }

                    // the password pebble
                    Item {
                        id: field
                        width: 320; height: 52
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: parent.height * 0.62

                        SequentialAnimation {
                            id: shake
                            NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -16; duration: 60 }
                            NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 14; duration: 90 }
                            NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: -8; duration: 80 }
                            NumberAnimation { target: field; property: "anchors.horizontalCenterOffset"; to: 0; duration: 70 }
                        }
                        Connections { target: root; function onFailedChanged() { if (root.failed) { shake.restart(); input.text = ""; } } }

                        Pebble {
                            id: pebble
                            seed: 2.1
                            amp: root.checking ? 3 : 1.8
                            rtl: 26; rtr: 26; rbr: 26; rbl: 26
                            fillTop: root.failed ? Qt.rgba(0.35, 0.16, 0.12, 0.95) : Qt.rgba(0.165, 0.227, 0.2, 0.94)
                            Behavior on fillTop { ColorAnimation { duration: 250 } }
                            NumberAnimation on t { from: 0; to: 100000; duration: 100000000; loops: Animation.Infinite }
                        }

                        TextInput {
                            id: input
                            anchors { fill: parent; leftMargin: 24; rightMargin: 24 }
                            verticalAlignment: TextInput.AlignVCenter
                            horizontalAlignment: TextInput.AlignHCenter
                            echoMode: TextInput.Password
                            passwordCharacter: "•"
                            font.family: Tune.uiFont
                            font.pixelSize: 20
                            color: Tune.parch
                            enabled: !root.checking && !root.leaving
                            focus: true
                            onAccepted: root.submit(text)
                            onTextChanged: if (text) root.failed = false
                            Component.onCompleted: forceActiveFocus()
                            Text {
                                anchors.centerIn: parent
                                visible: !input.text
                                text: root.checking ? "…" : root.failed ? "not quite" : "password"
                                font: input.font
                                color: Tune.parch
                                opacity: 0.45
                            }
                        }
                    }
                }
            }

            // release once the fade-out is done
            Timer {
                running: root.leaving
                interval: 450
                onTriggered: { lock.locked = false; root.leaving = false; }
            }
        }
    }
}
