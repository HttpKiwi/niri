pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.config
import qs.services

/**
 * Backdrop - the world layer, one per screen. A single shader pass draws the
 * wallpaper crossfade, time-of-day grade, light shafts, life and the clock
 * (shaders/world.frag). It only re-renders while something moves: the life
 * timer, a crossfade, or a grade transition. Never takes input.
 */
PanelWindow {
    id: root

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "grove:backdrop"
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: "#111a17"
    mask: Region {}

    // ---- wallpaper crossfade: load into the hidden image, fade, swap roles ----
    property bool frontIsA: true
    property string pending: ""
    property bool fading: false

    function show(path) {
        if (!path) return;
        if (fading) { pending = path; return; }
        const back = frontIsA ? imgB : imgA;
        if (back.source.toString() === "file://" + path && back.status === Image.Ready) {
            fadeTo(back);
            return;
        }
        back.source = "file://" + path;
    }
    function fadeTo(img) {
        fading = true;
        fade.to = img === imgB ? 1 : 0;
        fade.restart();
    }
    // Cover: crop the texture to the window's aspect, centred
    function cover(img) {
        const iw = img.implicitWidth, ih = img.implicitHeight;
        if (!iw || !ih || !width || !height) return Qt.vector4d(1, 1, 0, 0);
        const win = width / height, im = iw / ih;
        return win > im
            ? Qt.vector4d(1, im / win, 0, (1 - im / win) / 2)
            : Qt.vector4d(win / im, 1, (1 - win / im) / 2, 0);
    }

    Component.onCompleted: imgA.source = "file://" + Wallpaper.path
    Connections {
        target: Wallpaper
        function onPathChanged() { root.show(Wallpaper.path); }
    }

    Image {
        id: imgA
        visible: false
        asynchronous: true
        cache: false
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width, root.height)
        onStatusChanged: if (status === Image.Ready && !root.frontIsA && !root.fading) root.fadeTo(imgA)
    }
    Image {
        id: imgB
        visible: false
        asynchronous: true
        cache: false
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width, root.height)
        onStatusChanged: if (status === Image.Ready && root.frontIsA && !root.fading) root.fadeTo(imgB)
    }

    NumberAnimation {
        id: fade
        target: world
        property: "mixAB"
        duration: Tune.fadeSlow
        easing.type: Easing.InOutQuad
        onFinished: {
            root.frontIsA = world.mixAB < 0.5;
            root.fading = false;
            if (root.pending) {
                const p = root.pending;
                root.pending = "";
                root.show(p);
            }
        }
    }

    // ---- clock: rendered once a minute into a texture the shader blends in ----
    Item {
        id: clockItem
        x: root.width * 0.042
        y: root.height * 0.07
        width: clockCol.implicitWidth + 8
        height: clockCol.implicitHeight + 8
        readonly property real unit: Math.min(root.width, root.height * 16 / 9)

        Column {
            id: clockCol
            x: 4
            y: 4
            Text {
                text: Qt.formatTime(Ambience.now, "HH:mm")
                color: "white"
                font.family: Tune.displayFont
                font.pixelSize: clockItem.unit * 0.11
                font.letterSpacing: -clockItem.unit * 0.002
                lineHeight: 0.9
            }
            Text {
                x: clockItem.unit * 0.006
                text: Qt.formatDate(Ambience.now, "dddd, d MMMM")
                color: "white"
                font.family: Tune.displayFont
                font.pixelSize: clockItem.unit * 0.021
            }
        }
    }
    ShaderEffectSource {
        id: clockTexSrc
        sourceItem: clockItem
        hideSource: true
        visible: false
        // re-render only when the minute changes, not on every life tick
        live: false
    }
    Connections {
        target: Ambience
        function onNowChanged() { clockTexSrc.scheduleUpdate(); }
    }
    // first paint, and whenever the clock's size changes (screen, font)
    Connections {
        target: clockItem
        function onWidthChanged() { clockTexSrc.scheduleUpdate(); }
        function onHeightChanged() { clockTexSrc.scheduleUpdate(); }
    }

    // ---- life clock: only ticks while something on screen moves ----
    readonly property bool alive: world.shafts > 0.01 || world.pollen > 0.01 || world.fireflies > 0.01 || world.rain > 0.01
    readonly property real startMs: Date.now()
    Timer {
        interval: Math.round(1000 / Tune.lifeFps)
        repeat: true
        // windows cover the scene: keep the still grade, stop the life
        running: root.alive && root.visible && !Niri.backdropHiddenOn(root.screen?.name ?? "")
        onTriggered: world.t = (Date.now() - root.startMs) / 1000
    }

    ShaderEffect {
        id: world
        anchors.fill: parent
        fragmentShader: Qt.resolvedUrl("../shaders/world.frag.qsb")

        property var wallA: imgA
        property var wallB: imgB
        property var clockTex: clockTexSrc
        property real mixAB: 0
        property vector4d rectA: root.cover(imgA)
        property vector4d rectB: root.cover(imgB)
        property real t: 0
        property size res: Qt.size(width, height)
        property rect clockRect: Qt.rect(clockItem.x / width, clockItem.y / height, clockItem.width / width, clockItem.height / height)

        property color warmColor: Ambience.grade.warm
        property real warmAmt: Ambience.grade.warmAmt
        property color coolColor: Ambience.grade.cool
        property real coolAmt: Ambience.grade.coolAmt
        property real shafts: Ambience.grade.shafts
        property real pollen: Ambience.grade.pollen
        property real fireflies: Ambience.grade.fireflies
        property real rain: Ambience.weather === "rain" ? 1 : 0
        property real clockNight: Ambience.grade.clockNight
        property real vignette: Tune.vignette
        property real vigLeftPx: Tune.vignetteLeftPx

        Behavior on warmColor { ColorAnimation { duration: Tune.gradeFade } }
        Behavior on coolColor { ColorAnimation { duration: Tune.gradeFade } }
        Behavior on warmAmt { NumberAnimation { duration: Tune.gradeFade; easing.type: Easing.InOutSine } }
        Behavior on coolAmt { NumberAnimation { duration: Tune.gradeFade; easing.type: Easing.InOutSine } }
        Behavior on shafts { NumberAnimation { duration: Tune.gradeFade } }
        Behavior on pollen { NumberAnimation { duration: Tune.gradeFade } }
        Behavior on fireflies { NumberAnimation { duration: Tune.gradeFade } }
        Behavior on rain { NumberAnimation { duration: Tune.gradeFade } }
        Behavior on clockNight { NumberAnimation { duration: Tune.gradeFade } }
    }
}
