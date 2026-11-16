pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Notifications
import qs.config
import qs.services

/**
 * Island - one shape for every popup. At rest it's the seed; it grows right
 * along the bottom edge into a face (volume, recording, one-line message),
 * then shrinks back. A message leaves a mote that drifts up to the lights.
 *
 * Only the island on the focused screen reacts. Messages queue; volume cuts
 * in (you caused it); recording is the resting face while it runs.
 */
Item {
    id: root

    required property real t
    required property bool focusedScreen
    required property bool menuOpen
    required property string output
    readonly property bool night: Ambience.phase === "night"

    property string face: "seed"          // seed | vol | rec | msg | menu
    property var queue: []
    property Notification msg: null
    readonly property string restFace: Recorder.recording ? "rec" : "seed"

    // Overlay keeps its window wide while anything is out of the seed
    readonly property bool wide: face !== "seed" || width > Tune.seedSize + 1 || flyer.running

    signal moteLanded()

    onMenuOpenChanged: {
        if (menuOpen) {
            // the menu has the inbox: waiting messages don't replay after it closes
            hold.stop();
            Notifs.inFlight = Math.max(0, Notifs.inFlight - queue.length - (face === "msg" ? 1 : 0));
            queue = [];
            face = "menu";
        } else {
            next();
        }
    }

    function next() {
        if (menuOpen) { face = "menu"; return; }
        // drop notifications closed while they waited
        while (queue.length && !queue[0]) { queue = queue.slice(1); Notifs.inFlight = Math.max(0, Notifs.inFlight - 1); }
        if (queue.length) {
            msg = queue[0];
            queue = queue.slice(1);
            face = "msg";
            hold.interval = msg.urgency === NotificationUrgency.Critical ? Tune.urgentHold : Tune.messageHold;
            hold.restart();
        } else {
            face = restFace;
        }
    }
    function finishMessage() {
        if (face === "msg") flyer.launch();
        next();
    }

    onRestFaceChanged: if (face === "seed" || face === "rec") face = restFace

    Connections {
        target: Notifs
        enabled: root.focusedScreen
        function onArrived(n) {
            if (root.face === "menu") return;   // it's in the inbox already
            Notifs.inFlight++;
            root.queue = root.queue.concat([n]);
            if (root.face !== "msg" && root.face !== "vol" && root.face !== "menu") root.next();
        }
    }
    Connections {
        target: Audio
        enabled: root.focusedScreen
        function onChanged() {
            if (root.face === "menu") return;
            // a message being shown goes back to the front of the queue
            if (root.face === "msg" && root.msg) root.queue = [root.msg].concat(root.queue);
            root.face = "vol";
            hold.interval = Tune.volumeHold;
            hold.restart();
        }
    }
    Timer {
        id: hold
        onTriggered: root.face === "msg" ? root.finishMessage() : root.next()
    }

    // ---- shape ----
    readonly property real faceWidth: face === "menu" ? Tune.menuWidth
        : face === "vol" ? 230
        : face === "rec" ? 112
        : face === "msg" ? Math.min(Tune.islandMaxWidth - 16, msgRow.implicitWidth + 28)
        : Tune.seedSize
    width: faceWidth
    height: face === "menu" ? Tune.menuHeight : face === "seed" ? Tune.seedSize : Tune.pillHeight
    Behavior on width { NumberAnimation { duration: Tune.settle; easing.type: Easing.OutBack; easing.overshoot: 0.35 } }
    Behavior on height { NumberAnimation { duration: Tune.settle; easing.type: Easing.OutBack; easing.overshoot: 0.35 } }

    // Pond-surface body: pills are round, the menu is a pebble tighter in the corner it
    // grew from, and the edge never stops drifting (shaders/pebble.frag)
    readonly property bool pebble: face === "menu"
    Pebble {
        t: root.t
        seed: 1.3
        amp: root.face === "menu" ? 4.5 : root.face === "seed" ? 1.1 : 1.8
        rtl: root.pebble ? 34 : root.height / 2
        rtr: root.pebble ? 40 : root.height / 2
        rbr: root.pebble ? 36 : root.height / 2
        rbl: root.pebble ? 18 : root.height / 2
        opacity: root.face === "seed" ? 0.72 : 0.96
        Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    // seed: breathing light
    Glow {
        x: (Tune.seedSize - width) / 2
        y: root.height - Tune.seedSize + (Tune.seedSize - height) / 2
        width: Tune.seedSize * 0.62
        height: width
        visible: opacity > 0
        opacity: root.face === "seed" ? 0.65 + 0.35 * Math.sin(root.t * 2 * Math.PI / 6) : 0
        scale: 0.9 + 0.1 * Math.sin(root.t * 2 * Math.PI / 6)
        core: root.night ? "#fff3cf" : "#fbfde6"
        halo: root.night ? Tune.ember : Tune.sun
        coreSize: 0.12
    }

    // faces fade in once the shape has mostly grown
    component Face: Row {
        property string name
        anchors.verticalCenter: parent.verticalCenter
        x: 14
        spacing: 10
        visible: opacity > 0
        opacity: root.face === name ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: root.face === name ? 260 : 120 } }
    }
    component Icon: Text {
        font.family: Tune.iconFont
        font.pixelSize: 19
        color: Tune.parch
        anchors.verticalCenter: parent.verticalCenter
    }
    component Label: Text {
        font.family: Tune.uiFont
        font.pixelSize: 13
        color: Tune.parch
        anchors.verticalCenter: parent.verticalCenter
    }

    // faces clip to the shape so text never spills while it shrinks (the mote is outside this)
    Item {
        anchors.fill: parent
        clip: true

        Menu {
            width: Tune.menuWidth
            height: Tune.menuHeight
            anchors.bottom: parent.bottom
            open: root.face === "menu"
            output: root.output
            visible: opacity > 0
            opacity: root.face === "menu" ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: root.face === "menu" ? 300 : 100 } }
        }

        Face {
            name: "vol"
            Icon { text: Audio.muted ? "volume_off" : Audio.volume < 0.34 ? "volume_mute" : Audio.volume < 0.67 ? "volume_down" : "volume_up" }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 132; height: 6; radius: 3
                color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.14)
                Rectangle {
                    width: parent.width * (Audio.muted ? 0 : Math.min(1, Audio.volume))
                    height: parent.height; radius: 3
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "#8fb06a" }
                        GradientStop { position: 1; color: root.night ? Tune.ember : Tune.sun }
                    }
                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }
            }
            Label { text: Math.round(Audio.volume * 100); font.weight: Font.DemiBold; width: 26; horizontalAlignment: Text.AlignRight }
        }

        Face {
            name: "rec"
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 10; height: 10; radius: 5
                color: "#e9776a"
                opacity: 0.6 + 0.4 * Math.sin(root.t * 2 * Math.PI / 2.4)
            }
            Label { text: Recorder.elapsedText; font.weight: Font.DemiBold; font.features: { "tnum": 1 } }
        }

        Face {
            id: msgRow
            name: "msg"
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 18; height: 18; radius: 9
                color: "#6fbf87"
                clip: true
                Image {
                    anchors.fill: parent
                    source: root.msg?.image || (root.msg?.appIcon ? "image://icon/" + root.msg.appIcon : "")
                    sourceSize: Qt.size(36, 36)
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
            }
            Label { text: root.msg?.summary || root.msg?.appName || ""; font.weight: Font.Bold }
            Label {
                text: (root.msg?.body ?? "").replace(/\s+/g, " ")
                color: Qt.rgba(Tune.parch.r, Tune.parch.g, Tune.parch.b, 0.75)
                width: Math.min(implicitWidth, 300)
                elide: Text.ElideRight
                visible: text.length > 0
            }
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (point, button) => {
            if (root.face === "msg" && root.msg) {
                if (button === Qt.LeftButton) Notifs.activate(root.msg); else root.msg.dismiss();
                hold.stop();
                root.finishMessage();
            } else if (root.face === "seed") {
                Ui.open(root.output, Notifs.unread ? "inbox" : "all");
            }
        }
    }

    // ---- the mote: rises from the island to the lights ----
    property point moteTarget: Qt.point(0, 0)   // set by Overlay, in island coordinates
    Glow {
        id: flyer
        property bool running: anim.running
        function launch() { anim.restart(); }
        width: 14; height: 14
        visible: anim.running
        core: "#fff1c4"; halo: Tune.ember; coreSize: 0.2
        ParallelAnimation {
            id: anim
            NumberAnimation { target: flyer; property: "x"; from: root.width / 2; to: root.moteTarget.x - 7; duration: 1400; easing.type: Easing.InOutSine }
            NumberAnimation { target: flyer; property: "y"; from: root.height / 2 - 7; to: root.moteTarget.y - 7; duration: 1400; easing.type: Easing.OutCubic }
            onFinished: { Notifs.inFlight = Math.max(0, Notifs.inFlight - 1); root.moteLanded(); }
        }
    }
}
